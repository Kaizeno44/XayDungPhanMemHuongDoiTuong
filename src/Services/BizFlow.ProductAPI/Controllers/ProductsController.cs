using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using BizFlow.ProductAPI.Data;
using BizFlow.ProductAPI.DbModels; // Dùng namespace chứa Product của bạn

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

        // 1. Lấy danh sách sản phẩm từ MySQL
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Product>>> GetProducts()
        {
            return await _context.Products.ToListAsync();
        }

        // 2. Thêm sản phẩm mới (Để test)
        [HttpPost]
        public async Task<ActionResult<Product>> PostProduct(Product product)
        {
            _context.Products.Add(product);
            await _SaveChangesAsync();

            return CreatedAtAction(nameof(GetProducts), new { id = product.Id }, product);
        }
        
        // Hàm phụ trợ lưu async
        private async Task _SaveChangesAsync() 
        {
            await _context.SaveChangesAsync();
        }
    }
}