using BizFlow.OrderAPI.Data;
using BizFlow.OrderAPI.DTOs;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BizFlow.OrderAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class CustomersController : ControllerBase
    {
        private readonly OrderDbContext _context;

        public CustomersController(OrderDbContext context)
        {
            _context = context;
        }

        [HttpGet("{id}/history")]
        public async Task<IActionResult> GetHistory(Guid id)
        {
            var totalDebt = await _context.DebtLogs
                .Where(d => d.CustomerId == id)
                .SumAsync(d => d.Amount);

            var orders = await _context.Orders
                .Where(o => o.CustomerId == id)
                .OrderByDescending(o => o.OrderDate)
                .Select(o => new OrderHistoryItemDto
                {
                    Id = o.Id,
                    OrderCode = o.OrderCode,
                    TotalAmount = o.TotalAmount,
                    Status = o.Status,
                    OrderDate = o.OrderDate,
                    PaymentMethod = o.PaymentMethod
                })
                .ToListAsync();

            var response = new CustomerHistoryResponse
            {
                CustomerId = id,
                CurrentDebt = totalDebt,
                OrderCount = orders.Count,
                Orders = orders
            };

            return Ok(response);
        }
    }
}
