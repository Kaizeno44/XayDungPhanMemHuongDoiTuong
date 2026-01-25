using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using BizFlow.ProductAPI.Data;
using BizFlow.ProductAPI.DbModels;
using BizFlow.ProductAPI.DTOs;
using BizFlow.ProductAPI.Hubs;
using Microsoft.AspNetCore.SignalR;
using System.Collections.Generic;
using System.Threading.Tasks;
using System;
using System.Linq;

namespace BizFlow.ProductAPI.Controllers
{
    // ==========================================
    // 1. DTOs (Đã sửa lỗi Nullable & Khởi tạo)
    // ==========================================
    public class BulkImportRequest
    {
        public object? StoreId { get; set; } // Dùng object để nhận mọi kiểu dữ liệu từ App
        public string? Note { get; set; } // Cho phép null
        public List<ImportDetailDto> Details { get; set; } = new List<ImportDetailDto>(); // Khởi tạo để tránh null
    }

    public class ImportDetailDto
    {
        public object? ProductId { get; set; }
        public object? UnitId { get; set; }
        public object? ProductUnitId { get; set; }
        public object? Quantity { get; set; }
        public object? UnitCost { get; set; }
        public object? SupplierName { get; set; }
    }

    public class StockImportDto
    {
        public int Id { get; set; }
        public string ProductName { get; set; } = string.Empty;
        public string UnitName { get; set; } = string.Empty;
        public double Quantity { get; set; }
        public decimal CostPrice { get; set; }
        public string? SupplierName { get; set; }
        public DateTime ImportDate { get; set; }
        public string? Note { get; set; }
    }
    // ==========================================

    [Route("api/[controller]")]
    [ApiController]
    public class StockImportsController : ControllerBase
    {
        private readonly ProductDbContext _context;
        private readonly IHubContext<ProductHub> _hubContext;
        private readonly ILogger<StockImportsController> _logger;

        public StockImportsController(ProductDbContext context, IHubContext<ProductHub> hubContext, ILogger<StockImportsController> logger)
        {
            _context = context;
            _hubContext = hubContext;
            _logger = logger;
        }

        // GET: api/StockImports
        [HttpGet]
        public async Task<IActionResult> GetImports([FromQuery] Guid storeId)
        {
            try 
            {
                if (storeId == Guid.Empty) return BadRequest(new { message = "StoreId không hợp lệ" });

                var imports = await _context.StockImports
                    .Include(i => i.Product)
                    .Include(i => i.Unit)
                    .Where(i => i.StoreId == storeId)
                    .OrderByDescending(i => i.ImportDate)
                    .Select(i => new StockImportDto
                    {
                        Id = i.Id,
                        ProductName = i.Product != null ? i.Product.Name : "Sản phẩm đã xóa", 
                        UnitName = i.Unit != null ? i.Unit.UnitName : "N/A",
                        Quantity = i.Quantity,
                        CostPrice = (decimal)i.CostPrice,
                        SupplierName = i.SupplierName,
                        ImportDate = i.ImportDate,
                        Note = i.Note
                    })
                    .ToListAsync();

                return Ok(imports);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi GET History");
                return StatusCode(500, new { message = ex.Message });
            }
        }

        // POST: api/StockImports
        [HttpPost]
        public async Task<IActionResult> CreateImport([FromBody] BulkImportRequest request)
        {
            // 1. Kiểm tra request null
            if (request == null) return BadRequest(new { message = "Dữ liệu gửi lên không hợp lệ (null)" });

            // 2. Xử lý StoreId linh hoạt
            Guid finalStoreId = Guid.Parse("01ada08b-bd61-4fc6-8b70-fe958d463cc9"); // Mặc định Ba Tèo
            if (request.StoreId != null)
            {
                string storeIdStr = request.StoreId.ToString();
                if (Guid.TryParse(storeIdStr, out Guid parsedGuid) && parsedGuid != Guid.Empty)
                {
                    finalStoreId = parsedGuid;
                }
            }

            if (request.Details == null || !request.Details.Any())
                return BadRequest(new { message = "Danh sách nhập hàng trống" });

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                foreach (var item in request.Details)
                {
                    // 3. Parse các giá trị số linh hoạt (Sửa lỗi 400)
                    string pidStr = item.ProductId?.ToString() ?? "0";
                    string qtyStr = item.Quantity?.ToString() ?? "0";
                    string costStr = item.UnitCost?.ToString() ?? "0";
                    string uidStr = item.UnitId?.ToString() ?? "0";
                    string puidStr = item.ProductUnitId?.ToString() ?? "0";

                    int.TryParse(pidStr, out int pid);
                    double.TryParse(qtyStr, out double qty);
                    double.TryParse(costStr, out double cost);
                    int.TryParse(uidStr, out int uid);
                    int.TryParse(puidStr, out int puid);

                    // 4. Tìm sản phẩm
                    var product = await _context.Products
                        .Include(p => p.Inventory)
                        .Include(p => p.ProductUnits)
                        .FirstOrDefaultAsync(p => p.Id == pid);

                    if (product == null)
                        throw new Exception($"Không tìm thấy sản phẩm ID {pid}");

                    // 5. Xử lý UnitId linh hoạt
                    int finalUnitId = uid != 0 ? uid : puid;
                    var unit = product.ProductUnits.FirstOrDefault(u => u.Id == finalUnitId);
                    
                    if (unit == null)
                    {
                        unit = product.ProductUnits.FirstOrDefault(u => u.IsBaseUnit) 
                               ?? product.ProductUnits.FirstOrDefault();
                        
                        if (unit == null) throw new Exception($"Sản phẩm {product.Name} chưa được thiết lập đơn vị tính");
                    }

                    // 6. Tạo phiếu nhập
                    var stockImport = new StockImport
                    {
                        ProductId = product.Id,
                        UnitId = unit.Id,
                        Quantity = qty,
                        CostPrice = cost,
                        SupplierName = item.SupplierName ?? "Kho tổng",
                        Note = request.Note,
                        StoreId = finalStoreId,
                        ImportDate = DateTime.UtcNow
                    };
                    _context.StockImports.Add(stockImport);

                    // 5. Cập nhật tồn kho
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

                    // [SỬA LỖI TÍNH TOÁN]
                    // Ép kiểu (double) cho ConversionValue để nhân với Quantity (double)
                    double quantityInBaseUnit = item.Quantity * (double)unit.ConversionValue;
                    
                    product.Inventory.Quantity += quantityInBaseUnit;
                    product.Inventory.LastUpdated = DateTime.UtcNow;

                    // Gửi SignalR
                    if (_hubContext != null)
                    {
                        await _hubContext.Clients.All.SendAsync("ReceiveStockUpdate", product.Id, product.Inventory.Quantity);
                    }
                }

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return Ok(new { message = "Nhập kho thành công", count = request.Details.Count });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                _logger.LogError(ex, "Lỗi nhập kho");
                return BadRequest(new { message = ex.Message });
            }
        }
    }
}
