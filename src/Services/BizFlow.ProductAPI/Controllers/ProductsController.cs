using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using BizFlow.ProductAPI.Data;
using BizFlow.ProductAPI.DbModels;
using BizFlow.ProductAPI.DTOs;
using Microsoft.AspNetCore.Authorization;

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

        // ==========================================
        // 1. NHÓM API: TRA CỨU & HIỂN THỊ (Public)
        // ==========================================

        // 1.1 Lấy danh sách (Search, Filter, Paging)
        [HttpGet]
        public async Task<IActionResult> GetProducts(
            [FromQuery] string? keyword,
            [FromQuery] int categoryId = 0,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10)
        {
            var query = _context.Products
                .Include(p => p.Category)
                .Include(p => p.Inventory)
                .Include(p => p.ProductUnits)
                .AsQueryable();

            if (!string.IsNullOrEmpty(keyword))
                query = query.Where(p => p.Name.Contains(keyword) || p.Sku.Contains(keyword));

            if (categoryId > 0)
                query = query.Where(p => p.CategoryId == categoryId);

            int totalItems = await query.CountAsync();

            var products = await query
                .OrderByDescending(p => p.Id)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return Ok(new
            {
                TotalItems = totalItems,
                Page = page,
                PageSize = pageSize,
                Data = products
            });
        }

        // 1.2 Lấy chi tiết 1 sản phẩm
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

        // ==========================================
        // 2. NHÓM API: LOGIC BÁN HÀNG (Dành cho Order Service)
        // ==========================================

        // 2.1 Lấy giá bán theo Đơn vị tính (MỚI THÊM - Cực quan trọng cho ông C)
        // GET: /api/Products/2/price?unitId=4
        [HttpGet("{id}/price")]
        public async Task<IActionResult> GetProductPrice(int id, [FromQuery] int unitId)
        {
            // Tìm unit của sản phẩm đó
            var unit = await _context.ProductUnits
                .FirstOrDefaultAsync(u => u.ProductId == id && u.Id == unitId);

            if (unit == null) 
                return BadRequest(new { message = "Đơn vị tính không hợp lệ hoặc không thuộc sản phẩm này" });

            // Trả về giá chuẩn do Product Service quy định
            return Ok(new 
            { 
                ProductId = id,
                UnitId = unitId,
                UnitName = unit.UnitName,
                Price = unit.Price, // Giá bán (Order Service lấy giá này để tạo đơn)
                ConversionValue = unit.ConversionValue
            });
        }

        // 2.2 Kiểm tra tồn kho (Logic Đa đơn vị tính)
        // POST: /api/Products/check-stock
        [HttpPost("check-stock")]
        public async Task<IActionResult> CheckStock([FromBody] List<CheckStockRequest> requests)
        {
            var results = new List<CheckStockResult>();
            
            // Lấy danh sách ID sản phẩm cần check để query 1 lần cho nhanh
            var productIds = requests.Select(r => r.ProductId).Distinct().ToList();

            var products = await _context.Products
                .Include(p => p.Inventory)
                .Include(p => p.ProductUnits)
                .Where(p => productIds.Contains(p.Id))
                .ToListAsync();

            foreach (var req in requests)
            {
                var product = products.FirstOrDefault(p => p.Id == req.ProductId);

                // 1. Check Sản phẩm có tồn tại không
                if (product == null)
                {
                    results.Add(new CheckStockResult { ProductId = req.ProductId, IsEnough = false, Message = "Sản phẩm không tồn tại" });
                    continue;
                }

                // 2. Check Unit có hợp lệ không
                var unit = product.ProductUnits.FirstOrDefault(u => u.Id == req.UnitId);
                if (unit == null)
                {
                    results.Add(new CheckStockResult { ProductId = req.ProductId, IsEnough = false, Message = "Đơn vị tính không hợp lệ" });
                    continue;
                }

                // 3. LOGIC QUAN TRỌNG: Quy đổi ra đơn vị gốc để so sánh tồn kho
                // Ví dụ: Khách mua 5 Thiên (1 thiên = 1000 viên) => Cần 5000 viên
                double requestedQtyInBase = req.Quantity * unit.ConversionValue;
                double currentStock = product.Inventory?.Quantity ?? 0;

                if (currentStock >= requestedQtyInBase)
                {
                    results.Add(new CheckStockResult { 
                        ProductId = req.ProductId, 
                        IsEnough = true, 
                        Message = "Đủ hàng",
                        UnitPrice = unit.Price // Trả luôn giá để đỡ phải gọi API khác
                    });
                }
                else
                {
                    results.Add(new CheckStockResult
                    {
                        ProductId = req.ProductId,
                        IsEnough = false,
                        Message = $"Thiếu hàng. Kho còn: {currentStock} {product.BaseUnit}. Khách cần: {requestedQtyInBase} {product.BaseUnit}"
                    });
                }
            }

            return Ok(results);
        }

        // ==========================================
        // 3. NHÓM API: QUẢN TRỊ KHO & SẢN PHẨM (Admin/Staff)
        // ==========================================

        // 3.1 Tạo sản phẩm mới
        [HttpPost]
        // [Authorize(Roles = "Admin")] // Mở ra khi nào có Login
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

                // B. Tạo Inventory ban đầu
                var inventory = new Inventory
                {
                    ProductId = product.Id,
                    Quantity = request.InitialStock,
                    LastUpdated = DateTime.UtcNow
                };
                _context.Inventories.Add(inventory);

                // C. Tạo Units (Đơn vị tính)
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

                return Ok(new { message = "Tạo sản phẩm thành công", productId = product.Id });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, new { message = "Lỗi hệ thống: " + ex.Message });
            }
        }

        // 3.2 Nhập kho (Stock In) - Dùng để tăng số lượng
        [HttpPost("{id}/stock-in")]
        public async Task<IActionResult> StockIn(int id, [FromQuery] int quantity)
        {
            if (quantity <= 0) return BadRequest("Số lượng nhập phải > 0");

            var inventory = await _context.Inventories.FirstOrDefaultAsync(x => x.ProductId == id);
            if (inventory == null)
            {
                inventory = new Inventory { ProductId = id, Quantity = 0, LastUpdated = DateTime.UtcNow };
                _context.Inventories.Add(inventory);
            }

            inventory.Quantity += quantity;
            inventory.LastUpdated = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            return Ok(new { Message = "Nhập kho thành công", NewQuantity = inventory.Quantity });
        }
        // 3.3 API Dành riêng cho Order Service: Gửi số DƯƠNG để TRỪ kho
        // POST: /api/Products/stock
        [HttpPost("stock")]
        public async Task<IActionResult> ReduceStock([FromBody] UpdateStockRequest request)
        {
            if (request.QuantityChange <= 0)
                return BadRequest(new { message = "Số lượng bán phải là số dương (> 0)" });

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // 1. Tìm tồn kho
                var inventory = await _context.Inventories
                    .FirstOrDefaultAsync(x => x.ProductId == request.ProductId);

                if (inventory == null)
                    return BadRequest(new { message = "Sản phẩm chưa có dữ liệu tồn kho!" });

                // 2. Lấy đơn vị tính để quy đổi
                var unit = await _context.ProductUnits
                    .FirstOrDefaultAsync(u => u.Id == request.UnitId && u.ProductId == request.ProductId);

                if (unit == null)
                    return BadRequest(new { message = "Đơn vị tính không hợp lệ!" });

                // 3. Quy đổi ra đơn vị gốc
                // Ví dụ: Khách mua 10 Bao (Quantity = 10) -> Trừ 10
                // Ví dụ: Khách mua 1 Tấn (Quantity = 1) -> Trừ 20
                double quantityToDeduct = request.QuantityChange * unit.ConversionValue;

                // 4. Kiểm tra xem đủ hàng để trừ không
                if (inventory.Quantity < quantityToDeduct)
                {
                    return BadRequest(new 
                    { 
                        message = $"Kho không đủ hàng! Hiện còn: {inventory.Quantity}, Cần bán: {quantityToDeduct}" 
                    });
                }

                // 5. TRỪ KHO (Phép trừ thực hiện ở đây)
                inventory.Quantity -= quantityToDeduct;
                inventory.LastUpdated = DateTime.UtcNow;

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return Ok(new 
                { 
                    message = "Xuất kho thành công", 
                    currentStock = inventory.Quantity 
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