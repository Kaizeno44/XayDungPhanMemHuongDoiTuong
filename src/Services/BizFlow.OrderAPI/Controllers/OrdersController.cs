using BizFlow.OrderAPI.Data;
using BizFlow.OrderAPI.DbModels;
using BizFlow.OrderAPI.DTOs;
using BizFlow.OrderAPI.Services;
using BizFlow.OrderAPI.Hubs;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.SignalR;
using MassTransit;
using Shared.Kernel.Events;

namespace BizFlow.OrderAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class OrdersController : ControllerBase
    {
        private readonly OrderDbContext _context;
        private readonly ProductServiceClient _productService;
        private readonly IHubContext<NotificationHub> _hubContext;
        private readonly IPublishEndpoint _publishEndpoint;

        public OrdersController(
            OrderDbContext context,
            ProductServiceClient productService,
            IHubContext<NotificationHub> hubContext,
            IPublishEndpoint publishEndpoint)
        {
            _context = context;
            _productService = productService;
            _hubContext = hubContext;
            _publishEndpoint = publishEndpoint;
        }

        [HttpGet]
        public async Task<IActionResult> GetOrders()
        {
            var orders = await _context.Orders
                .OrderByDescending(o => o.OrderDate)
                .Select(o => new {
                    o.Id,
                    o.OrderCode,
                    o.OrderDate,
                    o.TotalAmount,
                    o.Status,
                    o.PaymentMethod,
                    o.CustomerId
                })
                .ToListAsync();

            return Ok(orders);
        }

        [HttpPost]
        public async Task<IActionResult> CreateOrder([FromBody] CreateOrderRequest request)
        {
            if (request.Items == null || !request.Items.Any())
                return BadRequest("Đơn hàng rỗng.");

            // =================================================================
            // 1️⃣ CHECK KHO + LẤY GIÁ (Synchronous - HTTP)
            // =================================================================
            // Vẫn giữ kiểm tra này để fail-fast (báo lỗi ngay) nếu không đủ hàng
            var checkStockRequest = request.Items.Select(i =>
                new CheckStockRequest
                {
                    ProductId = i.ProductId,
                    UnitId = i.UnitId,
                    Quantity = i.Quantity
                }).ToList();

            var stockResults = await _productService.CheckStockAsync(checkStockRequest);

            var notEnough = stockResults.FirstOrDefault(x => !x.IsEnough);
            if (notEnough != null)
                return BadRequest($"Sản phẩm ID {notEnough.ProductId} không đủ hàng.");

            // =================================================================
            // 2️⃣ TẠO OBJECT ĐƠN HÀNG
            // =================================================================
            var order = new Order
            {
                OrderCode = $"ORD-{DateTime.Now:yyyyMMddHHmmss}",
                CustomerId = request.CustomerId,
                StoreId = request.StoreId,
                OrderDate = DateTime.UtcNow,
                PaymentMethod = request.PaymentMethod,
                Status = "Pending",
                OrderItems = new List<OrderItem>()
            };

            decimal totalAmount = 0;

            foreach (var item in request.Items)
            {
                var stock = stockResults.First(x => x.ProductId == item.ProductId);
                var orderItem = new OrderItem
                {
                    ProductId = item.ProductId,
                    UnitId = item.UnitId,
                    Quantity = item.Quantity,
                    UnitPrice = stock.UnitPrice,
                    Total = stock.UnitPrice * item.Quantity
                };
                order.OrderItems.Add(orderItem);
                totalAmount += orderItem.Total;
            }
            order.TotalAmount = totalAmount;

            // =================================================================
            // 3️⃣ GHI NỢ & KIỂM TRA HẠN MỨC
            // =================================================================
            if (request.PaymentMethod == "Debt")
            {
                // A. Tính tổng nợ hiện tại
                var currentDebt = await _context.DebtLogs
                    .Where(d => d.CustomerId == request.CustomerId)
                    .SumAsync(d => d.Amount);

                // B. Hạn mức tín dụng (50 triệu)
                decimal creditLimit = 50_000_000;

                // C. Kiểm tra vượt hạn mức
                if (currentDebt + totalAmount > creditLimit)
                {
                    return BadRequest(
                        $"Khách đang nợ {currentDebt:N0}đ. " +
                        $"Đơn này {totalAmount:N0}đ sẽ vượt hạn mức {creditLimit:N0}đ.");
                }

                // D. Ghi log nợ
                _context.DebtLogs.Add(new DebtLog
                {
                    CustomerId = request.CustomerId,
                    StoreId = request.StoreId,
                    Amount = totalAmount,
                    Action = "Debit",
                    Reason = $"Nợ đơn hàng {order.OrderCode}",
                    CreatedAt = DateTime.UtcNow
                });

                // E. Đồng bộ bảng Customer
                var customer = await _context.Customers.FindAsync(request.CustomerId);
                if (customer != null)
                {
                    customer.CurrentDebt += totalAmount;
                }
            }

            // =================================================================
            // 4️⃣ LƯU ĐƠN VÀO DB (Transaction chốt đơn)
            // =================================================================
            order.Status = "Confirmed";
            _context.Orders.Add(order);
            await _context.SaveChangesAsync();

            // =================================================================
            // 5️⃣ [MỚI] GỬI SỰ KIỆN SANG RABBITMQ (Async)
            // =================================================================
            // Đây là bước quan trọng: Thông báo cho toàn hệ thống biết có đơn mới
            await _publishEndpoint.Publish(new OrderCreatedEvent
            {
                OrderId = order.Id,
                StoreId = order.StoreId,
                TotalAmount = order.TotalAmount,
                CreatedAt = order.OrderDate
            });

            Console.WriteLine($"--> [OrderAPI] Đã bắn sự kiện OrderCreatedEvent: {order.OrderCode}");

            // =================================================================
            // 6️⃣ TRỪ KHO (TẠM THỜI GIỮ LẠI)
            // =================================================================
            // Lưu ý: Sau khi bạn viết Consumer bên ProductAPI xong, bạn có thể 
            // XÓA đoạn code dưới đây để việc trừ kho diễn ra tự động qua RabbitMQ.
            // Hiện tại cứ giữ lại để đảm bảo kho vẫn bị trừ nếu Consumer chưa chạy.
            
            foreach (var item in order.OrderItems)
            {
                await _productService.DeductStockAsync(
                    item.ProductId,
                    item.UnitId,
                    item.Quantity);
            }

            // 7️⃣ BẮN SIGNALR SANG WEB ADMIN
            await _hubContext.Clients.Group("Admins").SendAsync("ReceiveNotification", new
            {
                title = "Đơn hàng mới! 🛒",
                message = $"Vừa có đơn hàng {order.OrderCode} trị giá {order.TotalAmount:N0}đ",
                orderId = order.Id
            });

            return Ok(new
            {
                Message = "Tạo đơn thành công",
                OrderId = order.Id,
                OrderCode = order.OrderCode
            });
        }
    }
}
