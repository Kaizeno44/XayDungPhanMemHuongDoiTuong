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
            // 1. Lấy tất cả đơn hàng đã xác nhận (Confirmed) kèm tên khách hàng
            var orders = await _context.Orders
                .Where(o => o.Status == "Confirmed")
                .Join(_context.Customers, o => o.CustomerId, c => c.Id, (o, c) => new { o, c })
                .Select(x => new {
                    Id = x.o.Id.ToString(),
                    x.o.CustomerId,
                    CustomerName = x.c.FullName,
                    // Nếu là nợ thì để số dương (màu đỏ), nếu là tiền mặt thì để số âm (màu xanh) theo logic frontend
                    Amount = x.o.PaymentMethod == "Debt" ? x.o.TotalAmount : -x.o.TotalAmount,
                    Action = x.o.PaymentMethod == "Debt" ? "Debit" : "Collect",
                    Reason = $"Thanh toán đơn hàng {x.o.OrderCode}",
                    CreatedAt = x.o.OrderDate
                })
                .ToListAsync();

            // 2. Lấy các bản ghi DebtLogs không liên quan đến đơn hàng (ví dụ: trả nợ thủ công)
            var orderIds = await _context.Orders.Where(o => o.Status == "Confirmed").Select(o => (Guid?)o.Id).ToListAsync();
            
            var manualLogs = await _context.DebtLogs
                .Where(l => l.RefOrderId == null || !orderIds.Contains(l.RefOrderId))
                .Join(_context.Customers, l => l.CustomerId, c => c.Id, (l, c) => new { l, c })
                .Select(x => new {
                    Id = x.l.Id.ToString(),
                    x.l.CustomerId,
                    CustomerName = x.c.FullName,
                    x.l.Amount,
                    x.l.Action,
                    x.l.Reason,
                    x.l.CreatedAt
                })
                .ToListAsync();

            // 3. Kết hợp và sắp xếp
            var allLogs = orders.Concat(manualLogs)
                .OrderByDescending(l => l.CreatedAt)
                .ToList();

            return Ok(allLogs);
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
