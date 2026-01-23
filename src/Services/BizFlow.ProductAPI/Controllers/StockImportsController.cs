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
        public Guid StoreId { get; set; }
        public string? Note { get; set; } // Cho phép null
        public List<ImportDetailDto> Details { get; set; } = new List<ImportDetailDto>(); // Khởi tạo để tránh null
    }

    public class ImportDetailDto
    {
        public int ProductId { get; set; }
        public int UnitId { get; set; }
        public int ProductUnitId { get; set; }
        public double Quantity { get; set; }
        public decimal UnitCost { get; set; }
        public string? SupplierName { get; set; } // Cho phép null
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
            if (request.StoreId == Guid.Empty)
                return BadRequest(new { message = "Thiếu StoreId" });

            if (request.Details == null || request.Details.Count == 0)
                return BadRequest(new { message = "Danh sách nhập hàng trống" });

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                foreach (var item in request.Details)
                {
                    // 1. Xử lý ID: Ưu tiên UnitId, nếu = 0 thì lấy ProductUnitId
                    int finalUnitId = item.UnitId != 0 ? item.UnitId : item.ProductUnitId;

                    // 2. Tìm sản phẩm
                    var product = await _context.Products
                        .Include(p => p.Inventory)
                        .FirstOrDefaultAsync(p => p.Id == item.ProductId);

                    if (product == null)
                        throw new Exception($"Sản phẩm ID {item.ProductId} không tồn tại");

                    // 3. Tìm Unit
                    var unit = await _context.ProductUnits.FirstOrDefaultAsync(u => u.Id == finalUnitId);
                    
                    if (unit == null)
                    {
                         unit = await _context.ProductUnits.FirstOrDefaultAsync(u => u.ProductId == item.ProductId && u.IsBaseUnit);
                         if (unit == null) throw new Exception($"Đơn vị tính ID {finalUnitId} không hợp lệ cho SP {product.Name}");
                    }

                    // 4. Tạo phiếu nhập
                    var stockImport = new StockImport
                    {
                        ProductId = item.ProductId,
                        UnitId = unit.Id,
                        Quantity = item.Quantity,
                        CostPrice = (double)item.UnitCost, // [SỬA] Giữ nguyên decimal, không ép kiểu double
                        SupplierName = item.SupplierName ?? "Kho tổng",
                        Note = request.Note,
                        StoreId = request.StoreId,
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