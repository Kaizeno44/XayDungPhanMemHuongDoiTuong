using BizFlow.OrderAPI.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BizFlow.OrderAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class DashboardController : ControllerBase
    {
        private readonly OrderDbContext _context;

        public DashboardController(OrderDbContext context)
        {
            _context = context;
        }

        [HttpGet("stats")]
        public async Task<IActionResult> GetDashboardStats()
        {
            try
            {
                var today = DateTime.UtcNow.Date;
                var sevenDaysAgo = today.AddDays(-6);

                // 1. Doanh thu hôm nay
                var todayRevenue = await _context.Orders
                    .Where(o => o.OrderDate.Date == today)
                    .SumAsync(o => o.TotalAmount);

                // 2. Tổng nợ
                var totalDebt = await _context.Customers
                    .SumAsync(c => c.CurrentDebt);
                
                // 3. Tổng số đơn hôm nay (Mới)
                var todayOrdersCount = await _context.Orders
                    .Where(o => o.OrderDate.Date == today)
                    .CountAsync();

                // 4. Biểu đồ 7 ngày
                var weeklyDataRaw = await _context.Orders
                    .Where(o => o.OrderDate.Date >= sevenDaysAgo && o.OrderDate.Date <= today)
                    .GroupBy(o => o.OrderDate.Date)
                    .Select(g => new { Date = g.Key, Revenue = g.Sum(o => o.TotalAmount) })
                    .ToListAsync();

                var weeklyChartData = Enumerable.Range(0, 7)
                    .Select(offset =>
                    {
                        var date = sevenDaysAgo.AddDays(offset);
                        var record = weeklyDataRaw.FirstOrDefault(x => x.Date == date);
                        return new { DayName = GetVietnameseDayName(date.DayOfWeek), Amount = record?.Revenue ?? 0 };
                    }).ToList();

                // 5. 🔥 TOP 5 SẢN PHẨM BÁN CHẠY (MỚI)
                // Lưu ý: Logic này join OrderItems để tính tổng số lượng bán ra
                var topProducts = await _context.OrderItems
                    .GroupBy(x => new { x.ProductId, x.UnitName }) // Group theo ID (Tên sản phẩm cần join bảng Product nếu muốn chính xác tên, ở đây giả sử lưu tên trong OrderItems)
                    .Select(g => new
                    {
                        ProductId = g.Key.ProductId,
                        ProductName = g.Max(x => x.UnitName), // Lấy tạm UnitName hoặc cần Join bảng Products để lấy Name
                        TotalSold = g.Sum(x => x.Quantity),
                        TotalRevenue = g.Sum(x => x.Total)
                    })
                    .OrderByDescending(x => x.TotalSold)
                    .Take(5)
                    .ToListAsync();

                // Để lấy tên sản phẩm đẹp hơn, ta cần lấy danh sách ProductId rồi query bảng Products (giả sử bảng Products nằm chung DB hoặc gọi qua Service).
                // Ở đây để đơn giản cho Microservices, tôi sẽ trả về danh sách TopItems dựa trên OrderItems đã lưu.

                return Ok(new
                {
                    TodayRevenue = todayRevenue,
                    TodayOrders = todayOrdersCount, // Thêm số đơn
                    TotalDebt = totalDebt,
                    WeeklyRevenue = weeklyChartData,
                    TopProducts = topProducts // Trả về Top 5
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Lỗi server: {ex.Message}");
            }
        }

        private static string GetVietnameseDayName(DayOfWeek day) => day switch
        {
            DayOfWeek.Monday => "T2", DayOfWeek.Tuesday => "T3", DayOfWeek.Wednesday => "T4",
            DayOfWeek.Thursday => "T5", DayOfWeek.Friday => "T6", DayOfWeek.Saturday => "T7", DayOfWeek.Sunday => "CN", _ => ""
        };
    }
}