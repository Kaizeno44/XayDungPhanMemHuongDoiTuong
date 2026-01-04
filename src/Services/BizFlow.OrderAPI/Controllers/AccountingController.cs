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
            var logs = await _context.DebtLogs
                .OrderByDescending(l => l.CreatedAt)
                .Select(l => new {
                    l.Id,
                    l.CustomerId,
                    l.Amount,
                    l.Action,
                    l.Reason,
                    l.CreatedAt
                })
                .ToListAsync();

            return Ok(logs);
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
