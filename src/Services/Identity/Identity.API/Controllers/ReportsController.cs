using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Identity.API.Data; // Để dùng AppDbContext
using Microsoft.EntityFrameworkCore;
using System.Security.Claims; // Để lấy User ID

namespace Identity.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    // 👇 CHỐT CHẶN QUAN TRỌNG: Chỉ Chủ Shop (Owner) hoặc Admin hệ thống mới được vào
    // Nhân viên (Employee) gọi vào đây sẽ bị chặn ngay (Lỗi 403 Forbidden)
    [Authorize(Roles = "Owner, SuperAdmin")] 
    public class ReportsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public ReportsController(AppDbContext context)
        {
            _context = context;
        }

        // API 1: Lấy số liệu tổng quan (Dashboard Stats)
        // Person E sẽ dùng API này để vẽ các thẻ số liệu trên đầu trang Admin
        // GET: api/reports/dashboard-stats
        [HttpGet("dashboard-stats")]
        public async Task<IActionResult> GetDashboardStats()
        {
            // 1. Lấy StoreId từ Token của người đang đăng nhập
            // (Vì là Owner nên chắc chắn có StoreId)
            var storeIdClaim = User.FindFirst("StoreId")?.Value;
            if (string.IsNullOrEmpty(storeIdClaim)) return BadRequest("Lỗi xác thực cửa hàng.");
            var storeId = Guid.Parse(storeIdClaim);

            // 2. Tính toán số liệu (Ví dụ đơn giản, sau này Person E sẽ viết logic phức tạp hơn)
            // Đếm tổng số sản phẩm trong kho
            var totalProducts = await _context.Products
                .CountAsync(p => p.StoreId == storeId);

            // Đếm tổng số khách hàng thân thiết
            var totalCustomers = await _context.Customers
                .CountAsync(c => c.StoreId == storeId);

            // Giả lập doanh thu (Vì chúng ta chưa làm bảng Order thật sự)
            // Sau này bạn sẽ thay bằng: _context.Orders.Where(...).Sum(o => o.Total)
            var fakeRevenue = 15000000; // 15 triệu
            var fakeOrdersToday = 45;   // 45 đơn

            // 3. Trả về kết quả JSON
            return Ok(new 
            {
                TotalRevenue = fakeRevenue,
                TotalOrders = fakeOrdersToday,
                ProductCount = totalProducts,
                CustomerCount = totalCustomers
            });
        }
    }
}