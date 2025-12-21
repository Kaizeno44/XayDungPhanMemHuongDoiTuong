using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using BizFlow.ProductAPI.Data;
using BizFlow.ProductAPI.DbModels;
using BizFlow.ProductAPI.DTOs;
using Microsoft.AspNetCore.Authorization; // 1. Bắt buộc phải có thư viện này

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

        // 1. GET: Ai cũng được xem -> KHÔNG CẦN [Authorize]
        [HttpGet("{id}")]
        public async Task<IActionResult> GetProductById(int id)
        {
            var product = await _context.Products
                .Include(p => p.ProductUnits)
                .Include(p => p.Category)
                .Include(p => p.Inventory)
                .FirstOrDefaultAsync(p => p.Id == id);

            if (product == null) return NotFound(new { message = "Không tìm thấy sản phẩm" });

            return Ok(product);
        }

        // 2. POST: Tạo sản phẩm -> CHỈ ADMIN (Cần đăng nhập)
        [HttpPost]
        // [Authorize] // <--- ĐÃ THÊM BẢO MẬT
        // [Authorize(Roles = "Admin")] // <--- Sau này mở dòng này để chặn chỉ Admin mới được tạo
        public async Task<IActionResult> CreateProduct([FromBody] CreateProductRequest request)
        {
            if (await _context.Products.AnyAsync(p => p.Sku == request.Sku))
                return BadRequest(new { message = "Mã SKU đã tồn tại!" });

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // A. Tạo Product
                var product = new Product
                {
                    Name = request.Name,
                    Sku = request.Sku,
                    CategoryId = request.CategoryId,
                    ImageUrl = request.ImageUrl,
                    Description = request.Description,
                    BaseUnit = request.BaseUnitName
                };

                _context.Products.Add(product);
                await _context.SaveChangesAsync();

                // B. Tạo Inventory
                var inventory = new Inventory
                {
                    ProductId = product.Id,
                    Quantity = request.InitialStock,
                    LastUpdated = DateTime.UtcNow
                };
                _context.Inventories.Add(inventory);

                // C. Tạo Units
                var baseUnit = new ProductUnit
                {
                    ProductId = product.Id,
                    UnitName = request.BaseUnitName,
                    ConversionValue = 1,
                    IsBaseUnit = true,
                    Price = request.BasePrice
                };
                _context.ProductUnits.Add(baseUnit);

                if (request.OtherUnits != null)
                {
                    foreach (var u in request.OtherUnits)
                    {
                        _context.ProductUnits.Add(new ProductUnit
                        {
                            ProductId = product.Id,
                            UnitName = u.UnitName,
                            ConversionValue = u.ConversionValue,
                            IsBaseUnit = false,
                            Price = u.Price
                        });
                    }
                }

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return CreatedAtAction(nameof(GetProductById), new { id = product.Id }, product);
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, new { message = "Lỗi hệ thống: " + ex.Message });
            }
        }

        // 3. PUT: Cập nhật kho -> NHÂN VIÊN/ADMIN (Cần đăng nhập)
        [HttpPut("stock")]
        // [Authorize] // <--- ĐÃ THÊM BẢO MẬT
        public async Task<IActionResult> UpdateStock([FromBody] UpdateStockRequest request)
        {
            var unit = await _context.ProductUnits.FindAsync(request.UnitId);
            if (unit == null) return BadRequest("Đơn vị tính không hợp lệ");

            var inventory = await _context.Inventories.FirstOrDefaultAsync(i => i.ProductId == request.ProductId);

            if (inventory == null)
            {
                inventory = new Inventory { ProductId = request.ProductId, Quantity = 0 };
                _context.Inventories.Add(inventory);
            }

            double currentStock = inventory.Quantity;
            double change = request.QuantityChange;
            double conversion = unit.ConversionValue;

            double quantityInBase = change * conversion;

            // Kiểm tra tồn kho (Logic chặn bán quá số lượng)
            if (quantityInBase < 0 && (currentStock + quantityInBase) < 0)
            {
                return BadRequest(new { message = "Kho không đủ hàng!" });
            }

            inventory.Quantity += quantityInBase;
            inventory.LastUpdated = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "Cập nhật kho thành công",
                currentStock = inventory.Quantity
            });
        }

        // 4. API INTERNAL: Để Service khác gọi -> Tạm thời mở để dễ test
        [HttpPost("check-stock")]
        public async Task<IActionResult> CheckStock([FromBody] List<CheckStockRequest> requests)
        {
            var results = new List<CheckStockResult>();
            var productIds = requests.Select(r => r.ProductId).Distinct().ToList();

            var products = await _context.Products
                .Include(p => p.Inventory)
                .Include(p => p.ProductUnits)
                .Where(p => productIds.Contains(p.Id))
                .ToListAsync();

            foreach (var req in requests)
            {
                var product = products.FirstOrDefault(p => p.Id == req.ProductId);

                if (product == null)
                {
                    results.Add(new CheckStockResult { ProductId = req.ProductId, IsEnough = false, Message = "Sản phẩm không tồn tại" });
                    continue;
                }

                var unit = product.ProductUnits.FirstOrDefault(u => u.Id == req.UnitId);
                if (unit == null)
                {
                    results.Add(new CheckStockResult { ProductId = req.ProductId, IsEnough = false, Message = "Đơn vị tính không hợp lệ" });
                    continue;
                }

                double requestedQtyInBase = req.Quantity * unit.ConversionValue;
                double currentStock = product.Inventory?.Quantity ?? 0;

                if (currentStock >= requestedQtyInBase)
                {
                    results.Add(new CheckStockResult { ProductId = req.ProductId, IsEnough = true, Message = "Đủ hàng" });
                }
                else
                {
                    results.Add(new CheckStockResult
                    {
                        ProductId = req.ProductId,
                        IsEnough = false,
                        Message = $"Thiếu hàng. Kho còn: {currentStock} {product.BaseUnit}. Khách cần: {requestedQtyInBase} {product.BaseUnit} ({req.Quantity} {unit.UnitName})"
                    });
                }
            }

            return Ok(results);
        }
        // 5. GET LIST: Lấy danh sách có tìm kiếm & phân trang
        // API: GET /api/Products?keyword=xi&categoryId=4&page=1&pageSize=10
        [HttpGet]
        public async Task<IActionResult> GetProducts(
            [FromQuery] string? keyword,
            [FromQuery] int categoryId = 0,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10)
        {
            // 1. Khởi tạo Query (chưa chạy vào DB ngay)
            var query = _context.Products
                .Include(p => p.Category)      // Kèm thông tin nhóm hàng
                .Include(p => p.Inventory)     // Kèm tồn kho
                .Include(p => p.ProductUnits)  // Kèm các đơn vị tính
                .AsQueryable();

            // 2. Lọc theo từ khóa (Nếu có)
            if (!string.IsNullOrEmpty(keyword))
            {
                // Tìm theo Tên hoặc theo mã SKU
                query = query.Where(p => p.Name.Contains(keyword) || p.Sku.Contains(keyword));
            }

            // 3. Lọc theo nhóm hàng (Nếu có chọn)
            if (categoryId > 0)
            {
                query = query.Where(p => p.CategoryId == categoryId);
            }

            // 4. Tính tổng số bản ghi (Để phía Client biết mà chia trang)
            int totalItems = await query.CountAsync();

            // 5. Phân trang & Thực thi truy vấn (Lúc này mới gọi xuống DB)
            var products = await query
                .OrderByDescending(p => p.Id) // Sắp xếp sản phẩm mới nhất lên đầu
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            // 6. Trả về kết quả chuẩn
            return Ok(new
            {
                TotalItems = totalItems,
                Page = page,
                PageSize = pageSize,
                Data = products
            });
        }
    }
}