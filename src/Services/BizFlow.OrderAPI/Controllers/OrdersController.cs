using BizFlow.OrderAPI.Data;
using BizFlow.OrderAPI.DbModels;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BizFlow.OrderAPI.Controllers
{
    [Route("api/orders")]
    [ApiController]
    public class OrdersController : ControllerBase
    {
        private readonly OrderDbContext _context;

        public OrdersController(OrderDbContext context)
        {
            _context = context;
        }

        // API nhận đơn hàng
        [HttpPost]
        public async Task<IActionResult> CreateOrder([FromBody] CreateOrderRequest request)
        {
            if (request.Items == null || request.Items.Count == 0) 
                return BadRequest("Đơn hàng rỗng!");

            // Tạo đơn mới
            var newOrder = new Order
            {
                Id = Guid.NewGuid(),
                CustomerId = request.CustomerId,
                OrderDate = DateTime.UtcNow,
                Status = "Confirmed",
                TotalAmount = 0
            };

            // Thêm sản phẩm vào đơn
            foreach (var item in request.Items)
            {
                var orderItem = new OrderItem
                {
                    Id = Guid.NewGuid(),
                    OrderId = newOrder.Id,
                    ProductId = item.ProductId,
                    UnitName = item.UnitName,
                    Quantity = item.Quantity,
                    UnitPrice = item.UnitPrice
                };
                newOrder.TotalAmount += (item.Quantity * item.UnitPrice);
                newOrder.OrderItems.Add(orderItem);
            }

            _context.Orders.Add(newOrder);

            // Xử lý ghi nợ
            if (request.IsDebt)
            {
                var customer = await _context.Customers.FindAsync(request.CustomerId);
                if (customer == null)
                {
                    customer = new Customer { Id = request.CustomerId, FullName = "Khách mới" };
                    _context.Customers.Add(customer);
                }

                var debtLog = new DebtLog
                {
                    CustomerId = request.CustomerId,
                    RefOrderId = newOrder.Id,
                    Amount = newOrder.TotalAmount,
                    Action = "Debit",
                    Note = $"Mua nợ đơn {newOrder.Id}"
                };
                _context.DebtLogs.Add(debtLog);
                customer.CurrentDebt += newOrder.TotalAmount;
            }

            await _context.SaveChangesAsync();
            return Ok(new { Success = true, Message = "Tạo đơn thành công!" });
        }
    }

    // Class hứng dữ liệu
    public class CreateOrderRequest
    {
        public Guid CustomerId { get; set; }
        public bool IsDebt { get; set; }
        public List<OrderItemRequest> Items { get; set; } = new();
    }

    public class OrderItemRequest
    {
        public int ProductId { get; set; }
        public string UnitName { get; set; } = "";
        public int Quantity { get; set; }
        public decimal UnitPrice { get; set; }
    }
}