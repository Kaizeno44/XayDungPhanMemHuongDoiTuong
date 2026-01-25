using BizFlow.OrderAPI.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BizFlow.OrderAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AccountingController : ControllerBase
    {
        private readonly OrderDbContext _context;

        public AccountingController(OrderDbContext context)
        {
            _context = context;
        }

        [HttpGet("cash-book")]
        public async Task<IActionResult> GetCashBook()
        {
            // Lấy tất cả đơn hàng đã xác nhận (Confirmed)
            var confirmedOrders = await _context.Orders
                .Where(o => o.Status == "Confirmed")
                .OrderByDescending(o => o.OrderDate)
                .Select(o => new
                {
                    Id = o.Id,
                    CustomerId = o.CustomerId,
                    CustomerName = _context.Customers.Where(c => c.Id == o.CustomerId).Select(c => c.FullName).FirstOrDefault() ?? "Khách lẻ",
                    Amount = o.TotalAmount,
                    Action = o.PaymentMethod == "Debt" ? "Ghi nợ" : "Thu tiền",
                    Reason = $"Thanh toán đơn hàng {o.OrderCode}",
                    CreatedAt = o.OrderDate
                })
                .ToListAsync();

            return Ok(confirmedOrders);
        }

        [HttpGet("revenue-stats")]
        public async Task<IActionResult> GetRevenueStats()
        {
            var startDate = DateTime.UtcNow.Date.AddDays(-6);
            
            var data = await _context.Orders
                .Where(o => o.OrderDate >= startDate)
                .GroupBy(o => o.OrderDate.Date)
                .Select(g => new {
                    Date = g.Key,
                    Revenue = g.Sum(o => o.TotalAmount)
                })
                .ToListAsync();

            var stats = data
                .Select(x => new {
                    Date = x.Date.ToString("yyyy-MM-dd"),
                    Revenue = x.Revenue
                })
                .OrderBy(g => g.Date)
                .ToList();

            return Ok(stats);
        }
    }
}
