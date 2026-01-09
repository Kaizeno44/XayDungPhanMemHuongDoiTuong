using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Identity.API.Data;
using Microsoft.EntityFrameworkCore;
using System.Text.Json; // 👈 Thêm thư viện này để đọc JSON

namespace Identity.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = "Owner, SuperAdmin")]
    public class ReportsController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IHttpClientFactory _httpClientFactory; // 👈 Khai báo công cụ gọi API

        // Inject HttpClient vào Constructor
        public ReportsController(AppDbContext context, IHttpClientFactory httpClientFactory)
        {
            _context = context;
            _httpClientFactory = httpClientFactory;
        }

        [HttpGet("dashboard-stats")]
        public async Task<IActionResult> GetDashboardStats()
        {
            var storeIdClaim = User.FindFirst("StoreId")?.Value;
            if (string.IsNullOrEmpty(storeIdClaim)) return BadRequest("Lỗi auth");
            var storeId = Guid.Parse(storeIdClaim);

            // 1. LẤY SỐ LIỆU CỦA MÌNH (Khách hàng) - Lấy trực tiếp từ DB
            var totalCustomers = await _context.Customers.CountAsync(c => c.StoreId == storeId);

            // 2. LẤY SỐ LIỆU CỦA ÔNG B (Sản phẩm, Doanh thu) - Gọi qua mạng
            var productStats = new ProductStatsDto(); // Tạo object rỗng để hứng
            
            try 
            {
                var client = _httpClientFactory.CreateClient();
                
                // ⚠️ LƯU Ý: Thay đổi cổng 5002 bên dưới thành cổng thật mà Person B đang chạy
                var response = await client.GetAsync($"https://localhost:5002/api/internal/stats?storeId={storeId}");
                
                if (response.IsSuccessStatusCode)
                {
                    // Đọc JSON trả về từ ông B map vào object
                    var jsonString = await response.Content.ReadAsStringAsync();
                    
                    // Cấu hình để không phân biệt hoa thường (productCount vs ProductCount)
                    var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
                    productStats = JsonSerializer.Deserialize<ProductStatsDto>(jsonString, options);
                }
            }
            catch
            {
                // Nếu gọi sang ông B bị lỗi (Server B tắt), ta chấp nhận hiển thị số 0
                // Không để lỗi này làm chết luôn API của mình
                Console.WriteLine("Không gọi được sang Product API");
            }

            // 3. GỘP LẠI VÀ TRẢ VỀ
            return Ok(new 
            {
                TotalRevenue = productStats?.Revenue ?? 0,      // Số thật từ B
                TotalOrders = productStats?.TotalOrders ?? 0,   // Số thật từ B
                ProductCount = productStats?.ProductCount ?? 0, // Số thật từ B
                CustomerCount = totalCustomers                  // Số thật từ A (Mình)
            });
        }
    }

    // Class này dùng để hứng dữ liệu JSON từ ông B gửi sang
    public class ProductStatsDto
    {
        public int ProductCount { get; set; }
        public decimal Revenue { get; set; }
        public int TotalOrders { get; set; }
    }
}