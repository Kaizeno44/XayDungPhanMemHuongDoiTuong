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

        // 1. API Sổ Quỹ (Cash Book)
        [HttpGet("cash-book")]
        public async Task<IActionResult> GetCashBook()
        {
            // Lấy tất cả đơn hàng đã xác nhận
            var confirmedOrders = await _context.Orders
                .Where(o => o.Status == "Confirmed")
                .OrderByDescending(o => o.OrderDate)
                .Select(o => new
                {
                    Id = o.Id,
                    CustomerId = o.CustomerId,
                    CustomerName = _context.Customers
                                    .Where(c => c.Id == o.CustomerId)
                                    .Select(c => c.FullName)
                                    .FirstOrDefault() ?? "Khách lẻ",
                    Amount = o.TotalAmount,
                    Action = o.PaymentMethod == "Debt" ? "Ghi nợ" : "Thu tiền",
                    Reason = $"Thanh toán đơn hàng {o.OrderCode}",
                    CreatedAt = o.OrderDate
                })
                .ToListAsync();

            return Ok(confirmedOrders);
        }

        // 2. API Thống Kê Doanh Thu
        [HttpGet("revenue-stats")]
        public async Task<IActionResult> GetRevenueStats()
        {
            var startDate = DateTime.UtcNow.Date.AddDays(-6);
            
            var data = await _context.Orders
                .Where(o => o.OrderDate >= startDate) // Nên thêm điều kiện Status == Confirmed nếu cần chính xác
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

        // 👇 3. QUAN TRỌNG: API Lịch Sử Nợ (Bạn đang thiếu hàm này)
        [HttpGet("debt-history/{customerId}")]
        public async Task<IActionResult> GetDebtHistory(Guid customerId)
        {
            var logs = await _context.DebtLogs
                .Where(d => d.CustomerId == customerId)
                .OrderByDescending(d => d.CreatedAt) // Mới nhất lên đầu
                .Select(d => new 
                {
                    Id = d.Id,
                    Amount = d.Amount,
                    Action = d.Action, // "Debit" (Ghi nợ), "Credit" (Trả nợ)
                    Reason = d.Reason,
                    CreatedAt = d.CreatedAt,
                    RefOrderId = d.RefOrderId
                })
                .ToListAsync();

            return Ok(logs);
        }
    }
}