using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authorization;
using Identity.API.Data;
using Identity.Domain.Entities;
using System.Security.Claims;

namespace Identity.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize] // 👈 Bắt buộc đăng nhập
    public class ProductsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public ProductsController(AppDbContext context)
        {
            _context = context;
        }

        // 1. API Tìm kiếm cho AI (Person D dùng cái này)
        // GET: api/products/search-for-ai?keyword=xi măng
        [HttpGet("search-for-ai")]
        public async Task<IActionResult> SearchProduct([FromQuery] string keyword)
        {
            // Lấy ID cửa hàng từ Token
            var storeIdClaim = User.FindFirst("StoreId")?.Value;
            if (string.IsNullOrEmpty(storeIdClaim)) return BadRequest("Không xác định được cửa hàng.");
            var storeId = Guid.Parse(storeIdClaim);

            // Tìm sản phẩm trong cửa hàng đó
            var product = await _context.Products
                .Where(p => p.StoreId == storeId && 
                           p.Name.ToLower().Contains(keyword.ToLower()))
                .FirstOrDefaultAsync(); // Lấy cái đầu tiên tìm thấy

            if (product == null) return NotFound("Không tìm thấy sản phẩm này trong kho.");

            return Ok(new 
            { 
                ProductId = product.Id, 
                ProductName = product.Name, 
                Price = product.Price,
                Unit = product.Unit // Trả về đơn vị để AI biết (VD: 5 "Bao")
            });
        }

        // 2. API Thêm sản phẩm (Dùng cái này để nhập mẫu dữ liệu test)
        // POST: api/products
        [HttpPost]
        public async Task<IActionResult> CreateProduct([FromBody] CreateProductRequest request)
        {
            var storeIdClaim = User.FindFirst("StoreId")?.Value;
            if (string.IsNullOrEmpty(storeIdClaim)) return BadRequest("Lỗi auth");

            var newProduct = new Product
            {
                Name = request.Name,
                Price = request.Price,
                Unit = request.Unit,
                StoreId = Guid.Parse(storeIdClaim)
            };

            _context.Products.Add(newProduct);
            await _context.SaveChangesAsync();

            return Ok(newProduct);
        }
    }

    public class CreateProductRequest
    {
        public string Name { get; set; }
        public decimal Price { get; set; }
        public string Unit { get; set; }
    }
}