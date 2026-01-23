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
        // 1. Thêm tham số StoreId để lọc dữ liệu đúng cửa hàng
        public async Task<IActionResult> GetDashboardStats([FromQuery] Guid storeId)
        {
            try
            {
                if (storeId == Guid.Empty)
                    return BadRequest(new { message = "StoreId is required" });

                // 2. XỬ LÝ THỜI GIAN CHUẨN UTC (Để so sánh đúng với Database)
                var vnNow = DateTime.UtcNow.AddHours(7); // Giờ hiện tại ở VN
                var todayVn = vnNow.Date; // 00:00 hôm nay tại VN

                // Chuyển mốc 00:00 VN về lại UTC để query DB
                // Ví dụ: 00:00 ngày 23/1 VN tương đương 17:00 ngày 22/1 UTC
                var startOfDayUtc = todayVn.AddHours(-7); 
                var endOfDayUtc = startOfDayUtc.AddDays(1);
                
                // Mốc đầu tháng (UTC)
                var firstDayOfMonthVn = new DateTime(todayVn.Year, todayVn.Month, 1);
                var firstDayOfMonthUtc = firstDayOfMonthVn.AddHours(-7);

                // 3. Lấy đơn hàng HÔM NAY (Lọc theo StoreId và Khung giờ UTC đã quy đổi)
                var todayOrders = await _context.Orders
                    .Where(o => o.StoreId == storeId && 
                                o.OrderDate >= startOfDayUtc && 
                                o.OrderDate < endOfDayUtc)
                    .Select(o => o.TotalAmount) // Chỉ lấy trường cần thiết để tối ưu
                    .ToListAsync();
                
                var todayRevenue = todayOrders.Sum();
                var todayOrdersCount = todayOrders.Count;

                // 4. Tổng nợ (Lọc theo StoreId)
                var totalDebt = await _context.Customers
                    .Where(c => c.StoreId == storeId)
                    .SumAsync(c => c.CurrentDebt);

                // 5. Biểu đồ doanh thu tháng (Lọc theo StoreId)
                // Lưu ý: GroupBy trong EF Core với MySQL đôi khi phức tạp về Timezone.
                // Cách an toàn: Lấy dữ liệu thô về rồi xử lý trên RAM (nếu dữ liệu chưa quá lớn)
                // Hoặc Group theo ngày UTC
                var monthlyOrders = await _context.Orders
                    .Where(o => o.StoreId == storeId && 
                                o.OrderDate >= firstDayOfMonthUtc && 
                                o.OrderDate < endOfDayUtc)
                    .Select(o => new { o.OrderDate, o.TotalAmount })
                    .ToListAsync();

                // Xử lý GroupBy ở phía C# (Client-evaluation) để đảm bảo chuyển đổi giờ VN đúng
                var dailyRevenueDict = monthlyOrders
                    .GroupBy(o => o.OrderDate.AddHours(7).Date) // Chuyển sang giờ VN rồi mới group
                    .ToDictionary(g => g.Key, g => g.Sum(x => x.TotalAmount));

                // Tạo danh sách đầy đủ các ngày trong tháng (để lấp đầy ngày không có đơn bằng 0)
                var daysToDisplay = todayVn.Day; // Hiển thị từ ngày 1 đến hôm nay
                var weeklyRevenue = Enumerable.Range(0, daysToDisplay)
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

                // 6. Top 5 Sản phẩm (Lọc theo StoreId thông qua bảng Order)
                var topProductStats = await _context.OrderItems
                    .Include(oi => oi.Order)
                    .Where(oi => oi.Order.StoreId == storeId && 
                                 oi.Order.OrderDate >= firstDayOfMonthUtc)
                    .GroupBy(oi => oi.ProductId)
                    .Select(g => new
                    {
                        ProductId = g.Key,
                        TotalSold = g.Sum(oi => oi.Quantity),
                        TotalRevenue = g.Sum(oi => oi.Total)
                    })
                    .OrderByDescending(x => x.TotalRevenue) // Sắp xếp theo doanh thu giảm dần
                    .Take(5)
                    .ToListAsync();

                // Map tên sản phẩm
                var topProducts = new List<object>();
                foreach (var item in topProductStats)
                {
                    string productName = $"Sản phẩm #{item.ProductId}";
                    try 
                    {
                        // Gọi Product Service để lấy tên thật (Nếu bạn đã setup ProductServiceClient)
                        // var p = await _productService.GetProductById(item.ProductId);
                        // if(p != null) productName = p.Name;
                    }
                    catch {}

                    topProducts.Add(new
                    {
                        item.ProductId,
                        ProductName = productName,
                        TotalSold = item.TotalSold,
                        TotalRevenue = item.TotalRevenue
                    });
                }

                return Ok(new
                {
                    TodayRevenue = todayRevenue,
                    TodayOrdersCount = todayOrdersCount,
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