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

        // 2. Tạo phiếu nhập kho (Quan trọng nhất)
        [HttpPost]
        public async Task<IActionResult> CreateImport([FromBody] CreateStockImportRequest request)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // 1. Kiểm tra sản phẩm và đơn vị
                var product = await _context.Products
                    .Include(p => p.Inventory)
                    .FirstOrDefaultAsync(p => p.Id == request.ProductId);
                
                if (product == null) return NotFound(new { message = "Sản phẩm không tồn tại" });

                var unit = await _context.ProductUnits
                    .FirstOrDefaultAsync(u => u.Id == request.UnitId && u.ProductId == request.ProductId);
                
                if (unit == null) return BadRequest(new { message = "Đơn vị tính không hợp lệ" });

                // 2. Lưu phiếu nhập
                var stockImport = new StockImport
                {
                    ProductId = request.ProductId,
                    UnitId = request.UnitId,
                    Quantity = request.Quantity,
                    CostPrice = request.CostPrice,
                    SupplierName = request.SupplierName,
                    Note = request.Note,
                    StoreId = request.StoreId,
                    ImportDate = DateTime.UtcNow
                };
                _context.StockImports.Add(stockImport);

                // 3. Cập nhật tồn kho
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

                // Quy đổi số lượng về đơn vị gốc
                double quantityInBaseUnit = request.Quantity * unit.ConversionValue;
                product.Inventory.Quantity += quantityInBaseUnit;
                product.Inventory.LastUpdated = DateTime.UtcNow;

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                // 4. Phát sóng cập nhật qua SignalR
                await _hubContext.Clients.All.SendAsync("ReceiveStockUpdate", product.Id, product.Inventory.Quantity);

                return Ok(new { message = "Nhập kho thành công", importId = stockImport.Id, newQuantity = product.Inventory.Quantity });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, new { message = "Lỗi hệ thống: " + ex.Message });
            }
        }
    }
}
