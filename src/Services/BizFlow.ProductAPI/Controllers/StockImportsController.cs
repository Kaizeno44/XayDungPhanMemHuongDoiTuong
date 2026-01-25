using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using BizFlow.ProductAPI.Data;
using BizFlow.ProductAPI.DbModels;
using BizFlow.ProductAPI.DTOs;
using BizFlow.ProductAPI.Hubs;
using Microsoft.AspNetCore.SignalR;

namespace BizFlow.ProductAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class StockImportsController : ControllerBase
    {
        private readonly ProductDbContext _context;
        private readonly IHubContext<ProductHub> _hubContext;
        private readonly ILogger<StockImportsController> _logger; // Thêm Logger để debug

        public StockImportsController(
            ProductDbContext context, 
            IHubContext<ProductHub> hubContext,
            ILogger<StockImportsController> logger)
        {
            _context = context;
            _hubContext = hubContext;
            _logger = logger;
        }

        // 1. Lấy lịch sử nhập kho
        [HttpGet]
        public async Task<IActionResult> GetImports([FromQuery] Guid storeId)
        {
            var imports = await _context.StockImports
                .Include(i => i.Product)
                .Include(i => i.Unit)
                .Where(i => i.StoreId == storeId)
                .OrderByDescending(i => i.ImportDate)
                .Select(i => new StockImportResponse
                {
                    Id = i.Id,
                    ProductName = i.Product.Name,
                    UnitName = i.Unit.UnitName,
                    Quantity = i.Quantity,
                    CostPrice = i.CostPrice,
                    SupplierName = i.SupplierName,
                    ImportDate = i.ImportDate,
                    Note = i.Note
                })
                .ToListAsync();

            return Ok(imports);
        }

        // 2. Tạo phiếu nhập kho (Đã hỗ trợ Bulk Import)
        [HttpPost]
        public async Task<IActionResult> CreateImport([FromBody] CreateStockImportRequest request)
        {
            // Validate dữ liệu đầu vào
            if (request.Details == null || !request.Details.Any())
            {
                return BadRequest(new { message = "Danh sách sản phẩm nhập kho trống." });
            }

            // Sử dụng Transaction để đảm bảo toàn vẹn dữ liệu
            using var transaction = await _context.Database.BeginTransactionAsync();
            
            // Danh sách để lưu các thay đổi kho nhằm gửi SignalR sau khi commit
            var stockUpdates = new List<(int ProductId, double NewQuantity)>();

            try
            {
                foreach (var item in request.Details)
                {
                    // 2.1. Kiểm tra sản phẩm
                    var product = await _context.Products
                        .Include(p => p.Inventory)
                        .FirstOrDefaultAsync(p => p.Id == item.ProductId);
                    
                    if (product == null) 
                    {
                        // Rollback ngay lập tức nếu dữ liệu sai
                        return NotFound(new { message = $"Không tìm thấy sản phẩm ID: {item.ProductId}" });
                    }

                    // 2.2. Kiểm tra đơn vị tính
                    var unit = await _context.ProductUnits
                        .FirstOrDefaultAsync(u => u.Id == item.UnitId && u.ProductId == item.ProductId);
                    
                    if (unit == null) 
                    {
                        return BadRequest(new { message = $"Đơn vị tính không hợp lệ cho sản phẩm: {product.Name}" });
                    }

                    // 2.3. Tạo bản ghi lịch sử nhập kho
                    var stockImport = new StockImport
                    {
                        ProductId = item.ProductId,
                        UnitId = item.UnitId,
                        Quantity = item.Quantity,
                        CostPrice = item.UnitCost, // Map từ DTO UnitCost
                        SupplierName = request.SupplierName,
                        Note = request.Note,
                        StoreId = request.StoreId,
                        ImportDate = DateTime.UtcNow
                    };
                    _context.StockImports.Add(stockImport);

                    // 2.4. Khởi tạo kho nếu chưa có
                    if (product.Inventory == null)
                    {
                        product.Inventory = new Inventory
                        {
                            ProductId = product.Id,
                            Quantity = 0,
                            LastUpdated = DateTime.UtcNow
                        };
                        _context.Inventories.Add(product.Inventory);
                    }

                    // 2.5. Quy đổi số lượng về đơn vị gốc và cộng kho
                    // Ví dụ: Nhập 1 Thùng (conversion=24) => Cộng 24 vào kho
                    double quantityInBaseUnit = item.Quantity * unit.ConversionValue;
                    product.Inventory.Quantity += quantityInBaseUnit;
                    product.Inventory.LastUpdated = DateTime.UtcNow;

                    // Lưu vào danh sách tạm để gửi SignalR sau
                    stockUpdates.Add((product.Id, product.Inventory.Quantity));
                }

                // Lưu xuống DB
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                // 3. Gửi SignalR cập nhật Real-time (Chỉ gửi khi Transaction thành công)
                foreach (var update in stockUpdates)
                {
                    await _hubContext.Clients.All.SendAsync("ReceiveStockUpdate", update.ProductId, update.NewQuantity);
                }

                return Ok(new { 
                    message = "Nhập kho thành công", 
                    itemsCount = request.Details.Count,
                    timestamp = DateTime.UtcNow 
                });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                _logger.LogError(ex, "Lỗi khi nhập kho");
                return StatusCode(500, new { message = "Lỗi hệ thống: " + ex.Message });
            }
        }
    }
}