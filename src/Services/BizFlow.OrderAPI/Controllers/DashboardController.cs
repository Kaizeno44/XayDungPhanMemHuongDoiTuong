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
                // 1. Xác định thời gian
                var today = DateTime.UtcNow.Date; // Lấy ngày hiện tại (theo giờ server)
                var sevenDaysAgo = today.AddDays(-6);

                // 2. Tính Doanh thu hôm nay
                // (Chỉ lấy đơn hàng đã hoàn thành hoặc thành công, tùy logic của bạn)
                var todayRevenue = await _context.Orders
                    .Where(o => o.OrderDate.Date == today) 
                    .SumAsync(o => o.TotalAmount);

                // 3. Tính Tổng nợ khách hàng
                // Lấy tổng cột CurrentDebt trong bảng Customers
                var totalDebt = await _context.Customers
                    .SumAsync(c => c.CurrentDebt);

                // 4. Chuẩn bị dữ liệu biểu đồ 7 ngày
                var weeklyDataRaw = await _context.Orders
                    .Where(o => o.OrderDate.Date >= sevenDaysAgo && o.OrderDate.Date <= today)
                    .GroupBy(o => o.OrderDate.Date)
                    .Select(g => new
                    {
                        Date = g.Key,
                        Revenue = g.Sum(o => o.TotalAmount)
                    })
                    .ToListAsync();

                // Chuẩn hóa dữ liệu (Điền số 0 cho những ngày không bán được gì)
                var weeklyChartData = Enumerable.Range(0, 7)
                    .Select(offset =>
                    {
                        var date = sevenDaysAgo.AddDays(offset);
                        var record = weeklyDataRaw.FirstOrDefault(x => x.Date == date);
                        return new
                        {
                            DayName = GetVietnameseDayName(date.DayOfWeek), // Hàm chuyển T2, T3...
                            Amount = record?.Revenue ?? 0
                        };
                    })
                    .ToList();

                return Ok(new
                {
                    TodayRevenue = todayRevenue,
                    TotalDebt = totalDebt,
                    WeeklyRevenue = weeklyChartData
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Lỗi server: {ex.Message}");
            }
        }

        // Hàm phụ để đổi tên thứ sang tiếng Việt cho thân thiện
        private static string GetVietnameseDayName(DayOfWeek day)
        {
            return day switch
            {
                DayOfWeek.Monday => "T2",
                DayOfWeek.Tuesday => "T3",
                DayOfWeek.Wednesday => "T4",
                DayOfWeek.Thursday => "T5",
                DayOfWeek.Friday => "T6",
                DayOfWeek.Saturday => "T7",
                DayOfWeek.Sunday => "CN",
                _ => ""
            };
        }
    }
}