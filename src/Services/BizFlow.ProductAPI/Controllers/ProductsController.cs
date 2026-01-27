using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using BizFlow.ProductAPI.Data;
using BizFlow.ProductAPI.DbModels;
using BizFlow.ProductAPI.DTOs;
using BizFlow.ProductAPI.Hubs;
using Microsoft.AspNetCore.SignalR;
// using Microsoft.AspNetCore.Authorization; // Mở lại khi cấu hình Auth

namespace BizFlow.ProductAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ProductsController : ControllerBase
    {
        private readonly ProductDbContext _context;
        private readonly IHubContext<ProductHub> _hubContext;

        public ProductsController(ProductDbContext context, IHubContext<ProductHub> hubContext)
        {
            _context = context;
            _hubContext = hubContext;
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

        // 1.2 Lấy tổng số lượng sản phẩm
        [HttpGet("count")]
        public async Task<IActionResult> GetProductCount()
        {
            var count = await _context.Products.CountAsync();
            return Ok(new { count });
        }

        // 1.3 Lấy chi tiết 1 sản phẩm
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
        // 2. NHÓM API: LOGIC BÁN HÀNG (Cho Order Service)
        // ==========================================

        // 2.1 Lấy giá bán theo Đơn vị tính
        [HttpGet("{id}/price")]
        public async Task<IActionResult> GetProductPrice(int id, [FromQuery] int unitId)
        {
            var unit = await _context.ProductUnits
                .FirstOrDefaultAsync(u => u.ProductId == id && u.Id == unitId);

            if (unit == null)
                return BadRequest(new { message = "Đơn vị tính không hợp lệ" });

            return Ok(new
            {
                ProductId = id,
                UnitId = unitId,
                UnitName = unit.UnitName,
                Price = unit.Price,
                ConversionValue = unit.ConversionValue
            });
        }

        // 2.2 Kiểm tra tồn kho (Read-only)
        [HttpPost("check-stock")]
        public async Task<IActionResult> CheckStock([FromBody] CheckStockRequestWrapperDto wrapper)
        {
            var results = new List<CheckStockResult>();
            var productIds = wrapper.Requests.Select(r => r.ProductId).Distinct().ToList();

            var products = await _context.Products
                .Include(p => p.Inventory)
                .Include(p => p.ProductUnits)
                .Where(p => productIds.Contains(p.Id))
                .ToListAsync();

            foreach (var req in wrapper.Requests)
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
                    results.Add(new CheckStockResult { ProductId = req.ProductId, IsEnough = false, Message = "Sai đơn vị tính" });
                    continue;
                }

                double requestedQtyInBase = req.Quantity * unit.ConversionValue;
                double currentStock = product.Inventory?.Quantity ?? 0;

                if (currentStock >= requestedQtyInBase)
                    results.Add(new CheckStockResult { ProductId = req.ProductId, IsEnough = true, Message = "Đủ hàng", UnitPrice = unit.Price });
                else
                    results.Add(new CheckStockResult { ProductId = req.ProductId, IsEnough = false, Message = $"Thiếu hàng. Còn: {currentStock}" });
            }

            return Ok(results);
        }

        // ==========================================
        // 3. NHÓM API: QUẢN TRỊ & CẬP NHẬT KHO
        // ==========================================

        // 3.1 Tạo sản phẩm 
        [HttpPost]
        // [Authorize(Roles = "Admin")]
        public async Task<IActionResult> CreateProduct([FromBody] CreateProductRequest request)
        {
            if (await _context.Products.AnyAsync(p => p.Sku == request.Sku))
                return BadRequest(new { message = "Mã SKU đã tồn tại!" });

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // 1. Lưu thông tin chính (Product)
                var product = new Product
                {
                    Name = request.Name,
                    Sku = request.Sku,
                    CategoryId = request.CategoryId,
                    BaseUnit = request.BaseUnitName,
                    ImageUrl = request.ImageUrl,
                    Description = request.Description
                };
                _context.Products.Add(product);
                await _context.SaveChangesAsync();

                // 2. Lưu tồn kho ban đầu (Inventory)
                var inventory = new Inventory
                {
                    ProductId = product.Id,
                    Quantity = request.InitialStock,
                    LastUpdated = DateTime.UtcNow
                };
                _context.Inventories.Add(inventory);

                // 3. Lưu đơn vị gốc (Base Unit)
                var baseUnit = new ProductUnit
                {
                    ProductId = product.Id,
                    UnitName = request.BaseUnitName,
                    ConversionValue = 1,
                    IsBaseUnit = true,
                    Price = request.BasePrice
                };
                _context.ProductUnits.Add(baseUnit);

                // 4. Lưu các đơn vị quy đổi khác
                if (request.OtherUnits != null && request.OtherUnits.Any())
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

        // 3.2 CẬP NHẬT KHO THÔNG MINH (Smart Update Stock)
        // PUT: /api/Products/stock?mode=out
        [HttpPut("stock")]
        public async Task<IActionResult> UpdateStock(
            [FromBody] UpdateStockRequest request,
            [FromQuery] string mode = "auto")
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var inventory = await _context.Inventories.FirstOrDefaultAsync(x => x.ProductId == request.ProductId);

                // Nếu chưa có kho -> Tạo mới
                if (inventory == null)
                {
                    bool isDeducting = mode == "out" || (mode == "auto" && request.QuantityChange < 0);
                    if (isDeducting) return BadRequest(new { message = "Sản phẩm chưa có dữ liệu tồn kho, không thể xuất bán!" });

                    inventory = new Inventory { ProductId = request.ProductId, Quantity = 0, LastUpdated = DateTime.UtcNow };
                    _context.Inventories.Add(inventory);
                }

                var unit = await _context.ProductUnits.FirstOrDefaultAsync(u => u.Id == request.UnitId && u.ProductId == request.ProductId);
                if (unit == null) return BadRequest(new { message = "Đơn vị tính không hợp lệ!" });

                // --- LOGIC XỬ LÝ DẤU ---
                double quantityBase = 0;
                double absQuantity = Math.Abs(request.QuantityChange);

                if (mode == "out")
                {
                    // Trừ kho
                    quantityBase = -1 * absQuantity * unit.ConversionValue;
                }
                else if (mode == "in")
                {
                    // Cộng kho
                    quantityBase = absQuantity * unit.ConversionValue;
                }
                else // mode == "auto"
                {
                    quantityBase = request.QuantityChange * unit.ConversionValue;
                }

                // Kiểm tra tồn kho (Nếu là phép trừ)
                if (quantityBase < 0 && (inventory.Quantity + quantityBase < 0))
                {
                    return BadRequest(new { message = $"Kho không đủ hàng! Hiện còn: {inventory.Quantity}, Cần trừ: {Math.Abs(quantityBase)}" });
                }

                // Cập nhật
                inventory.Quantity += quantityBase;
                inventory.LastUpdated = DateTime.UtcNow;

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                // Phát sóng cập nhật tồn kho qua SignalR
                await _hubContext.Clients.All.SendAsync("ReceiveStockUpdate", request.ProductId, inventory.Quantity);

                return Ok(new
                {
                    message = quantityBase < 0 ? "Xuất kho thành công" : "Nhập kho thành công",
                    currentStock = inventory.Quantity,
                    changedAmount = quantityBase
                });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, new { message = "Lỗi hệ thống: " + ex.Message });
            }
        }

        // 3.3 Lấy danh sách sản phẩm sắp hết hàng
        [HttpGet("low-stock")]
        public async Task<IActionResult> GetLowStockProducts([FromQuery] double threshold = 10)
        {
            var lowStockProducts = await _context.Products
                .Include(p => p.Inventory)
                .Where(p => p.Inventory.Quantity <= threshold)
                .Select(p => new
                {
                    p.Id,
                    p.Name,
                    p.Sku,
                    CurrentStock = p.Inventory.Quantity
                })
                .OrderBy(p => p.CurrentStock)
                .ToListAsync();

            return Ok(lowStockProducts);
        }

        // 3.4 Cập nhật sản phẩm
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateProduct(int id, [FromBody] UpdateProductRequest request)
        {
            if (id != request.Id) return BadRequest(new { message = "ID không khớp" });

            var product = await _context.Products
                .Include(p => p.Inventory)
                .Include(p => p.ProductUnits)
                .FirstOrDefaultAsync(p => p.Id == id);

            if (product == null) return NotFound(new { message = "Không tìm thấy sản phẩm" });

            if (product.Sku != request.Sku && await _context.Products.AnyAsync(p => p.Sku == request.Sku))
                return BadRequest(new { message = "Mã SKU đã tồn tại!" });

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                product.Name = request.Name;
                product.Sku = request.Sku;
                product.CategoryId = request.CategoryId;
                product.ImageUrl = request.ImageUrl;
                product.Description = request.Description;

                if (request.InitialStock.HasValue)
                {
                    if (product.Inventory == null)
                    {
                        product.Inventory = new Inventory { ProductId = id, Quantity = request.InitialStock.Value, LastUpdated = DateTime.UtcNow };
                        _context.Inventories.Add(product.Inventory);
                    }
                    else
                    {
                        product.Inventory.Quantity = request.InitialStock.Value;
                        product.Inventory.LastUpdated = DateTime.UtcNow;
                    }
                }

                if (request.Units != null)
                {
                    foreach (var uDto in request.Units)
                    {
                        if (uDto.Id.HasValue)
                        {
                            var unit = product.ProductUnits.FirstOrDefault(x => x.Id == uDto.Id.Value);
                            if (unit != null)
                            {
                                unit.UnitName = uDto.UnitName;
                                unit.Price = uDto.Price;
                                unit.ConversionValue = uDto.ConversionValue;
                                unit.IsBaseUnit = uDto.IsBaseUnit;
                            }
                        }
                        else
                        {
                            _context.ProductUnits.Add(new ProductUnit
                            {
                                ProductId = id,
                                UnitName = uDto.UnitName,
                                Price = uDto.Price,
                                ConversionValue = uDto.ConversionValue,
                                IsBaseUnit = uDto.IsBaseUnit
                            });
                        }
                    }
                }

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                // SignalR update
                if (product.Inventory != null)
                    await _hubContext.Clients.All.SendAsync("ReceiveStockUpdate", product.Id, product.Inventory.Quantity);

                return Ok(new { message = "Cập nhật sản phẩm thành công" });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, new { message = "Lỗi hệ thống: " + ex.Message });
            }
        }

        // 3.5 Xóa sản phẩm
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteProduct(int id)
        {
            var product = await _context.Products.FindAsync(id);
            if (product == null) return NotFound(new { message = "Không tìm thấy sản phẩm" });

            try
            {
                _context.Products.Remove(product);
                await _context.SaveChangesAsync();
                return Ok(new { message = "Xóa sản phẩm thành công" });
            }
            catch (Exception)
            {
                return StatusCode(500, new { message = "Không thể xóa sản phẩm do có ràng buộc dữ liệu (đơn hàng, kho...)" });
            }
        }
    }
}