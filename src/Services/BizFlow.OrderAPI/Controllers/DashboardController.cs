using BizFlow.OrderAPI.Data;
using BizFlow.OrderAPI.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BizFlow.OrderAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class DashboardController : ControllerBase
    {
        private readonly OrderDbContext _context;
        private readonly ProductServiceClient _productService;

        public DashboardController(OrderDbContext context, ProductServiceClient productService)
        {
            _context = context;
            _productService = productService;
        }

        [HttpGet("stats")]
        // 1. Làm StoreId thành tùy chọn để linh hoạt trong môi trường Dev
        public async Task<IActionResult> GetDashboardStats([FromQuery] Guid? storeId)
        {
            try
            {
                // 2. XỬ LÝ THỜI GIAN CHUẨN UTC (Để so sánh đúng với Database)
                var vnNow = DateTime.UtcNow.AddHours(7); // Giờ hiện tại ở VN
                var todayVn = vnNow.Date; // 00:00 hôm nay tại VN

                // Mốc đầu tháng (VN)
                var firstDayOfMonthVn = new DateTime(todayVn.Year, todayVn.Month, 1);
                // Chuyển mốc đầu tháng VN về lại UTC để query DB
                var firstDayOfMonthUtc = firstDayOfMonthVn.AddHours(-7);
                
                // Mốc cuối tháng (VN)
                var lastDayOfMonthVn = firstDayOfMonthVn.AddMonths(1).AddDays(-1);
                var endOfMonthUtc = lastDayOfMonthVn.AddDays(1).AddHours(-7);

                // 3. Lấy đơn hàng TRONG THÁNG (Chỉ lấy đơn đã xác nhận - Confirmed)
                // Thử lọc theo StoreId trước
                var monthlyOrders = await _context.Orders
                    .Where(o => o.StoreId == storeId && 
                                o.Status == "Confirmed" && 
                                o.OrderDate >= firstDayOfMonthUtc && 
                                o.OrderDate < endOfMonthUtc)
                    .Select(o => new { o.OrderDate, o.TotalAmount })
                    .ToListAsync();

                // Nếu không có dữ liệu cho StoreId này, lấy toàn bộ hệ thống (để dev dễ nhìn thấy số liệu)
                if (!monthlyOrders.Any())
                {
                    monthlyOrders = await _context.Orders
                        .Where(o => o.Status == "Confirmed" && 
                                    o.OrderDate >= firstDayOfMonthUtc && 
                                    o.OrderDate < endOfMonthUtc)
                        .Select(o => new { o.OrderDate, o.TotalAmount })
                        .ToListAsync();
                    Console.WriteLine($"--> Dashboard: Không tìm thấy đơn Confirmed cho Store {storeId}, lấy toàn bộ {monthlyOrders.Count} đơn Confirmed.");
                }
                else
                {
                    Console.WriteLine($"--> Dashboard: Tìm thấy {monthlyOrders.Count} đơn cho Store {storeId}.");
                }
                
                var monthRevenue = monthlyOrders.Sum(x => x.TotalAmount);
                var monthOrdersCount = monthlyOrders.Count;

                // 4. Tổng nợ (Lọc theo StoreId nếu có)
                var customerQuery = _context.Customers.AsQueryable();
                if (storeId.HasValue && storeId.Value != Guid.Empty)
                    customerQuery = customerQuery.Where(c => c.StoreId == storeId.Value);
                
                var totalDebt = await customerQuery.SumAsync(c => c.CurrentDebt);

                // 5. Biểu đồ doanh thu tháng
                // Xử lý GroupBy ở phía C# (Client-evaluation) để đảm bảo chuyển đổi giờ VN đúng
                var dailyRevenueDict = monthlyOrders
                    .GroupBy(o => o.OrderDate.AddHours(7).Date) // Chuyển sang giờ VN rồi mới group
                    .ToDictionary(g => g.Key, g => g.Sum(x => x.TotalAmount));

                // Tạo danh sách đầy đủ các ngày trong tháng (để lấp đầy ngày không có đơn bằng 0)
                var daysInMonth = DateTime.DaysInMonth(todayVn.Year, todayVn.Month);
                var weeklyRevenue = Enumerable.Range(0, daysInMonth)
                    .Select(offset =>
                    {
                        var date = firstDayOfMonthVn.AddDays(offset);
                        return new
                        {
                            DayName = $"{date.Day}/{date.Month}",
                            Amount = dailyRevenueDict.ContainsKey(date) ? dailyRevenueDict[date] : 0
                        };
                    })
                    .ToList();

                // 6. Top 5 Sản phẩm TRONG THÁNG (Chỉ tính đơn Confirmed)
                // Thử lọc theo StoreId trước
                var topProductStats = await _context.OrderItems
                    .Include(oi => oi.Order)
                    .Where(oi => oi.Order.StoreId == storeId && 
                                 oi.Order.Status == "Confirmed" && 
                                 oi.Order.OrderDate >= firstDayOfMonthUtc && 
                                 oi.Order.OrderDate < endOfMonthUtc)
                    .GroupBy(oi => oi.ProductId)
                    .Select(g => new
                    {
                        ProductId = g.Key,
                        TotalSold = g.Sum(oi => oi.Quantity),
                        TotalRevenue = g.Sum(oi => oi.Total)
                    })
                    .OrderByDescending(x => x.TotalRevenue)
                    .Take(5)
                    .ToListAsync();

                // Nếu không có dữ liệu cho StoreId này, lấy toàn bộ hệ thống
                if (!topProductStats.Any())
                {
                    topProductStats = await _context.OrderItems
                        .Include(oi => oi.Order)
                        .Where(oi => oi.Order.Status == "Confirmed" && 
                                     oi.Order.OrderDate >= firstDayOfMonthUtc && 
                                     oi.Order.OrderDate < endOfMonthUtc)
                        .GroupBy(oi => oi.ProductId)
                        .Select(g => new
                        {
                            ProductId = g.Key,
                            TotalSold = g.Sum(oi => oi.Quantity),
                            TotalRevenue = g.Sum(oi => oi.Total)
                        })
                        .OrderByDescending(x => x.TotalRevenue)
                        .Take(5)
                        .ToListAsync();
                }

                // Map tên sản phẩm (Gọi sang Product Service)
                var topProducts = new List<object>();
                foreach (var item in topProductStats)
                {
                    string productName = $"Sản phẩm #{item.ProductId}";
                    try 
                    {
                        var p = await _productService.GetProductByIdAsync(item.ProductId);
                        if(p != null) productName = p.Name;
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"--> Dashboard: Lỗi lấy tên SP {item.ProductId}: {ex.Message}");
                    }

                    topProducts.Add(new
                    {
                        ProductId = item.ProductId,
                        ProductName = productName,
                        TotalSold = item.TotalSold,
                        TotalRevenue = item.TotalRevenue
                    });
                }

                return Ok(new
                {
                    TodayRevenue = monthRevenue,
                    TodayOrdersCount = monthOrdersCount,
                    TotalDebt = totalDebt,
                    WeeklyRevenue = weeklyRevenue,
                    TopProducts = topProducts
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi server", error = ex.Message });
            }
        }
    }
}
