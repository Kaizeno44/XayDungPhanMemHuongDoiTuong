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
                // 1. Xác định thời gian (Dùng UtcNow để đồng bộ với lúc tạo đơn)
                var now = DateTime.UtcNow;
                var today = now.Date; 
                var tomorrow = today.AddDays(1);
                var sevenDaysAgo = today.AddDays(-6);

                // 2. Tính Doanh thu hôm nay và số đơn hàng hôm nay
                // Sử dụng so sánh khoảng thời gian để MySQL dễ tối ưu và tránh lỗi .Date
                var todayOrders = await _context.Orders
                    .Where(o => o.OrderDate >= today && o.OrderDate < tomorrow)
                    .ToListAsync();
                
                var todayRevenue = todayOrders.Sum(o => o.TotalAmount);
                var todayOrdersCount = todayOrders.Count;

                // 3. Tính Tổng nợ khách hàng
                var totalDebt = await _context.Customers.SumAsync(c => c.CurrentDebt);

                // 4. Chuẩn bị dữ liệu biểu đồ theo tháng (Tất cả các ngày trong tháng hiện tại)
                var firstDayOfMonth = new DateTime(today.Year, today.Month, 1);
                
                // Lấy tất cả đơn hàng từ đầu tháng đến hết ngày hôm nay
                var monthlyOrders = await _context.Orders
                    .Where(o => o.OrderDate >= firstDayOfMonth && o.OrderDate < tomorrow)
                    .ToListAsync();

                var monthlyDataRaw = monthlyOrders
                    .GroupBy(o => new { o.OrderDate.Year, o.OrderDate.Month, o.OrderDate.Day })
                    .Select(g => new
                    {
                        Year = g.Key.Year,
                        Month = g.Key.Month,
                        Day = g.Key.Day,
                        Revenue = g.Sum(o => o.TotalAmount)
                    })
                    .ToList();

                // Chuẩn hóa dữ liệu: Hiển thị từ ngày 1 đến ngày hiện tại (hoặc hết tháng)
                // Để biểu đồ tập trung vào những ngày đã qua và hiện tại
                int daysToDisplay = today.Day; 
                var monthlyChartData = Enumerable.Range(0, daysToDisplay)
                    .Select(offset =>
                    {
                        var date = firstDayOfMonth.AddDays(offset);
                        var record = monthlyDataRaw.FirstOrDefault(x => x.Year == date.Year && x.Month == date.Month && x.Day == date.Day);
                        return new
                        {
                            DayName = date.ToString("dd/MM"),
                            Amount = record?.Revenue ?? 0
                        };
                    })
                    .ToList();

                // 5. Top 5 sản phẩm bán chạy nhất tháng
                var topProducts = await _context.OrderItems
                    .Include(oi => oi.Order)
                    .Where(oi => oi.Order.OrderDate >= firstDayOfMonth)
                    .GroupBy(oi => oi.ProductId)
                    .Select(g => new
                    {
                        ProductId = g.Key,
                        TotalQuantity = g.Sum(oi => oi.Quantity),
                        TotalRevenue = g.Sum(oi => oi.Total)
                    })
                    .OrderByDescending(x => x.TotalQuantity)
                    .Take(5)
                    .ToListAsync();

                return Ok(new
                {
                    TodayRevenue = todayRevenue,
                    TodayOrdersCount = todayOrdersCount,
                    TotalDebt = totalDebt,
                    WeeklyRevenue = monthlyChartData, // Giữ tên key cũ để không phải sửa Frontend nhiều
                    TopProducts = topProducts
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
