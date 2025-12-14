using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using BizFlow.ProductAPI.Data;
using BizFlow.ProductAPI.DbModels; 
using BizFlow.ProductAPI.DTOs;

namespace BizFlow.ProductAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ProductsController : ControllerBase
    {
        private readonly ProductDbContext _context;

        public ProductsController(ProductDbContext context)
        {
            _context = context;
        }

        // 1. Lấy danh sách sản phẩm (Kèm theo các đơn vị tính)
        // GET: api/products
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var products = await _context.Products
                .Include(p => p.ProductUnits) // Nối bảng Unit
                .Include(p => p.Inventory)    // Nối bảng Kho
                .ToListAsync();
            return Ok(products);
        }

        // 2. Tạo sản phẩm mới
        // POST: api/products
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] CreateProductRequest request)
        {
            // Bước 1: Tạo sản phẩm
            var product = new Product
            {
                Name = request.Name,
                BaseUnit = request.BaseUnit,
                CategoryId = request.CategoryId,
                IsActive = true
            };

            // Bước 2: Tạo các đơn vị tính
            if (request.Units != null)
            {
                foreach (var u in request.Units)
                {
                    product.ProductUnits.Add(new ProductUnit
                    {
                        UnitName = u.UnitName,
                        ConversionRate = u.ConversionRate,
                        Price = u.Price,
                        IsDefault = u.IsDefault
                    });
                }
            }

            // Bước 3: Tạo kho mặc định (Ban đầu tồn kho = 0)
            product.Inventory = new Inventory 
            { 
                Quantity = 0,     // Mặc định bằng 0
                MinStockLevel = 10, 
                LastUpdated = DateTime.UtcNow 
            };

            _context.Products.Add(product);
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Tạo sản phẩm thành công", ProductId = product.Id });
        }

        // 3. API Nhập kho (Cộng thêm hàng vào kho)
        // PUT: api/products/{id}/stock-in
        [HttpPut("{id}/stock-in")]
        public async Task<IActionResult> StockIn(int id, [FromBody] decimal quantity)
        {
            var inventory = await _context.Inventories.FirstOrDefaultAsync(i => i.ProductId == id);
            if (inventory == null) return NotFound("Chưa có kho cho sản phẩm này");

            inventory.Quantity += quantity; // Cộng dồn
            inventory.LastUpdated = DateTime.UtcNow;
            
            await _context.SaveChangesAsync();
            return Ok(new { Message = "Nhập kho thành công", NewStock = inventory.Quantity });
        }

        // 4. API Trừ kho (Dành cho ông C - Bán hàng)
        // PUT: api/products/deduct-stock
        [HttpPut("deduct-stock")]
        public async Task<IActionResult> DeductStock([FromBody] DeductStockRequest request)
        {
            // Tìm Unit mà khách chọn mua
            var unit = await _context.ProductUnits.FindAsync(request.UnitId);
            if (unit == null) return BadRequest("Đơn vị tính không tồn tại");

            // Tìm kho của sản phẩm đó
            var inventory = await _context.Inventories
                .FirstOrDefaultAsync(i => i.ProductId == unit.ProductId);

            if (inventory == null) return NotFound("Lỗi dữ liệu kho");

            // LOGIC QUY ĐỔI: (Số lượng khách mua) * (Tỷ lệ quy đổi)
            // Ví dụ: Mua 2 Tấn (Rate 20) -> Trừ 40 Bao
            var quantityToDeduct = request.Quantity * unit.ConversionRate;

            if (inventory.Quantity < quantityToDeduct)
            {
                return BadRequest($"Không đủ hàng! Kho còn: {inventory.Quantity} (Đơn vị gốc), Khách cần: {quantityToDeduct}");
            }

            // Trừ kho
            inventory.Quantity -= quantityToDeduct;
            inventory.LastUpdated = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            return Ok(new { Message = "Xuất kho thành công", RemainingStock = inventory.Quantity });
        }
    }
}