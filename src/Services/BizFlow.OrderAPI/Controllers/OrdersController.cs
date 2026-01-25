using BizFlow.OrderAPI.Data;
using BizFlow.OrderAPI.DbModels;
using BizFlow.OrderAPI.DTOs;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BizFlow.OrderAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class OrdersController : ControllerBase
    {
        private readonly OrderDbContext _context;

        public OrdersController(OrderDbContext context)
        {
            _context = context;
        }

        [HttpPost]
        public async Task<IActionResult> CreateOrder([FromBody] CreateOrderRequest request)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // Tạo Order mới
                var order = new Order
                {
                    Id = Guid.NewGuid(),
                    CustomerId = request.CustomerId,
                    StoreId = request.StoreId,
                    OrderDate = DateTime.UtcNow,
                    Status = "Completed",
                    PaymentMethod = request.PaymentMethod,
                    // Ép kiểu double -> decimal
                    TotalAmount = 0 
                };

                decimal calculatedTotal = 0;

                foreach (var item in request.Items)
                {
                    var orderItem = new OrderItem
                    {
                        Id = Guid.NewGuid(),
                        OrderId = order.Id,
                        ProductId = item.ProductId,
                        UnitId = item.UnitId,
                        UnitName = item.UnitName ?? "Cái",
                        Quantity = item.Quantity,
                        UnitPrice = (decimal)item.UnitPrice, // Ép kiểu
                        Total = (decimal)(item.Quantity * item.UnitPrice)
                    };
                    
                    calculatedTotal += orderItem.Total;
                    order.OrderItems.Add(orderItem); // Dùng OrderItems thay vì Items
                }

                order.TotalAmount = calculatedTotal;
                
                // Tạo Order Code ngẫu nhiên
                order.OrderCode = "ORD-" + new Random().Next(1000, 9999);

                _context.Orders.Add(order);

                // Xử lý nợ nếu thanh toán ghi nợ
                if (request.PaymentMethod == "Debt" && request.CustomerId.HasValue)
                {
                    var customer = await _context.Customers.FindAsync(request.CustomerId.Value);
                    if (customer != null)
                    {
                        customer.CurrentDebt += calculatedTotal;

                        // Ghi log nợ
                        var debtLog = new DebtLog
                        {
                            Id = Guid.NewGuid(),
                            CustomerId = customer.Id,
                            StoreId = customer.StoreId,
                            Amount = calculatedTotal,
                            Action = "Order",
                            Reason = $"Mua đơn hàng #{order.OrderCode}",
                            CreatedAt = DateTime.UtcNow
                        };
                        _context.DebtLogs.Add(debtLog);
                    }
                }

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return Ok(new { Message = "Tạo đơn hàng thành công", OrderId = order.Id });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, new { Message = ex.Message });
            }
        }
    }
}