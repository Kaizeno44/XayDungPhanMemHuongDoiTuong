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

        public StockImportsController(ProductDbContext context, IHubContext<ProductHub> hubContext)
        {
            _context = context;
            _hubContext = hubContext;
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

        // 2. Tạo phiếu nhập kho (Bulk Import - Hỗ trợ nhập nhiều món)
        [HttpPost]
        public async Task<IActionResult> CreateImport([FromBody] CreateStockImportRequest request)
        {
            // Kiểm tra dữ liệu đầu vào
            if (request.Details == null || !request.Details.Any())
            {
                return BadRequest(new { message = "Danh sách sản phẩm nhập kho trống!" });
            }

            // Bắt đầu transaction để đảm bảo tính toàn vẹn dữ liệu
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var createdImportIds = new List<int>();

                // Duyệt qua từng sản phẩm trong danh sách gửi lên
                foreach (var item in request.Details)
                {
                    // 1. Kiểm tra sản phẩm có tồn tại không
                    var product = await _context.Products
                        .Include(p => p.Inventory)
                        .FirstOrDefaultAsync(p => p.Id == item.ProductId);
                    
                    if (product == null) 
                    {
                        // Rollback nếu có bất kỳ sản phẩm nào lỗi
                        await transaction.RollbackAsync(); 
                        return NotFound(new { message = $"Sản phẩm ID {item.ProductId} không tồn tại" });
                    }

                    // 2. Kiểm tra đơn vị tính
                    var unit = await _context.ProductUnits
                        .FirstOrDefaultAsync(u => u.Id == item.UnitId && u.ProductId == item.ProductId);
                    
                    if (unit == null) 
                    {
                        await transaction.RollbackAsync();
                        return BadRequest(new { message = $"Đơn vị tính không hợp lệ cho sản phẩm: {product.Name}" });
                    }

                    // 3. Tạo phiếu nhập (StockImport Record)
                    var stockImport = new StockImport
                    {
                        ProductId = item.ProductId,
                        UnitId = item.UnitId,
                        Quantity = item.Quantity,
                        CostPrice = item.UnitCost, // Map từ UnitCost
                        SupplierName = request.SupplierName ?? "N/A",
                        Note = request.Notes,      // Dùng chung ghi chú cho cả đơn
                        StoreId = request.StoreId,
                        ImportDate = DateTime.UtcNow
                    };
                    _context.StockImports.Add(stockImport);

                    // 4. Cập nhật tồn kho (Inventory)
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

                    // Quy đổi số lượng về đơn vị gốc và cộng dồn
                    double quantityInBaseUnit = item.Quantity * unit.ConversionValue;
                    product.Inventory.Quantity += quantityInBaseUnit;
                    product.Inventory.LastUpdated = DateTime.UtcNow;

                    // Lưu tạm thời để lấy ID cho lần lặp sau (nếu cần) hoặc để EF theo dõi
                    // Tuy nhiên SaveChangesAsync cuối cùng sẽ hiệu quả hơn, 
                    // nhưng ta cần ImportId nếu muốn trả về chi tiết. 
                    // Ở đây ta gom SaveChanges xuống cuối để tối ưu.

                    // 5. Gửi Realtime Update (SignalR) cho client biết tồn kho mới ngay lập tức
                    await _hubContext.Clients.All.SendAsync("ReceiveStockUpdate", product.Id, product.Inventory.Quantity);
                }

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return Ok(new 
                { 
                    message = "Nhập kho thành công", 
                    count = request.Details.Count,
                    storeId = request.StoreId 
                });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, new { message = "Lỗi hệ thống: " + ex.Message });
            }
        }
    }
}