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
    [Authorize] // 👈 Bắt buộc phải đăng nhập mới được gọi
    public class CustomersController : ControllerBase
    {
        private readonly AppDbContext _context;

        public CustomersController(AppDbContext context)
        {
            _context = context;
        }

        // API 1: Tìm kiếm khách hàng (Cho Dropdown Search)
        // GET: api/customers/search?phone=098
        [HttpGet("search")]
        public async Task<IActionResult> SearchCustomers([FromQuery] string phone)
        {
            // 1. Lấy ID cửa hàng từ Token của nhân viên đang đăng nhập
            var storeIdClaim = User.FindFirst("StoreId")?.Value;
            if (string.IsNullOrEmpty(storeIdClaim)) return BadRequest("Không xác định được cửa hàng.");
            var storeId = Guid.Parse(storeIdClaim);

            // 2. Chỉ tìm khách CỦA CỬA HÀNG ĐÓ (Bảo mật)
            var customers = await _context.Customers
                .Where(c => c.StoreId == storeId && 
                           (c.PhoneNumber.Contains(phone) || c.FullName.ToLower().Contains(phone.ToLower())))
                .Select(c => new 
                { 
                    c.Id, 
                    c.FullName, 
                    c.PhoneNumber, 
                    c.DebtBalance // Trả về số nợ để Person C hiển thị cảnh báo nếu nợ nhiều
                })
                .Take(10) // Chỉ lấy 10 người cho nhẹ
                .ToListAsync();

            return Ok(customers);
        }

        // API 2: Tạo nhanh khách hàng (Cho nút dấu +)
        // POST: api/customers
        [HttpPost]
        public async Task<IActionResult> CreateCustomer([FromBody] CreateCustomerRequest request)
        {
            // 1. Lấy ID cửa hàng từ Token
            var storeIdClaim = User.FindFirst("StoreId")?.Value;
            if (string.IsNullOrEmpty(storeIdClaim)) return BadRequest("Không xác định được cửa hàng.");
            
            // 2. Kiểm tra xem sđt đã tồn tại trong cửa hàng này chưa
            var exists = await _context.Customers
                .AnyAsync(c => c.StoreId == Guid.Parse(storeIdClaim) && c.PhoneNumber == request.PhoneNumber);
            
            if (exists) return BadRequest("Số điện thoại này đã tồn tại trong danh sách khách hàng.");

            // 3. Tạo khách mới
            var newCustomer = new Customer
            {
                FullName = request.FullName,
                PhoneNumber = request.PhoneNumber,
                Address = request.Address,
                StoreId = Guid.Parse(storeIdClaim), // Gán cứng vào Store của nhân viên
                DebtBalance = 0
            };

            _context.Customers.Add(newCustomer);
            await _context.SaveChangesAsync();

            return Ok(newCustomer);
        }
    }

    // Class DTO (Data Transfer Object) để hứng dữ liệu gửi lên
    public class CreateCustomerRequest
    {
        public string FullName { get; set; }
        public string PhoneNumber { get; set; }
        public string? Address { get; set; }
    }
}