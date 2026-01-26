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
        public async Task<IActionResult> GetDashboardStats([FromQuery] Guid? storeId)
        {
            if (!storeId.HasValue) return BadRequest("StoreId is required");

            try
            {
                // 1. Xác định thời gian
                var today = DateTime.UtcNow.Date; // Lấy ngày hiện tại (theo giờ server)
                var sevenDaysAgo = today.AddDays(-6);

                // 2. Tính Doanh thu hôm nay và số đơn hàng hôm nay
                var todayOrdersQuery = _context.Orders
                    .Where(o => o.StoreId == storeId.Value && o.OrderDate.Date == today);
                var todayRevenue = await todayOrdersQuery.SumAsync(o => o.TotalAmount);
                var todayOrdersCount = await todayOrdersQuery.CountAsync();

                // 3. Tính Tổng nợ khách hàng (Lọc theo StoreId)
                var totalDebt = await _context.Customers
                    .Where(c => c.StoreId == storeId.Value)
                    .SumAsync(c => c.CurrentDebt);

                // 4. Chuẩn bị dữ liệu biểu đồ 7 ngày
                var weeklyDataRaw = await _context.Orders
                    .Where(o => o.StoreId == storeId.Value && o.OrderDate.Date >= sevenDaysAgo && o.OrderDate.Date <= today)
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

                // 5. Top 5 sản phẩm bán chạy nhất tháng (Chỉ tính đơn hàng Confirmed)
                var firstDayOfMonth = new DateTime(today.Year, today.Month, 1);
                var topProducts = await _context.OrderItems
                    .Include(oi => oi.Order)
                    .Where(oi => oi.Order.StoreId == storeId.Value && oi.Order.OrderDate >= firstDayOfMonth && oi.Order.Status == "Confirmed")
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
                    WeeklyRevenue = weeklyChartData,
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
