using BizFlow.OrderAPI.Data;
using BizFlow.OrderAPI.DbModels;
using BizFlow.OrderAPI.DTOs;
using BizFlow.OrderAPI.Services;
using Microsoft.AspNetCore.Mvc;
using BizFlow.OrderAPI.Hubs; // 1. Thêm namespace chứa Hub
using Microsoft.AspNetCore.SignalR; // 2. Thêm thư viện SignalR
namespace BizFlow.OrderAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class OrdersController : ControllerBase
    {
        private readonly OrderDbContext _context;
        private readonly ProductServiceClient _productService;
        private readonly IHubContext<NotificationHub> _hubContext;
        public OrdersController(
            OrderDbContext context,
            ProductServiceClient productService,
            IHubContext<NotificationHub> hubContext) // 4. Inject HubContext vào Constructor
        {
            _context = context;
            _productService = productService;
            _hubContext = hubContext;
        }

        [HttpPost]
        public async Task<IActionResult> CreateOrder(
            [FromBody] CreateOrderRequest request)
        {
            if (request.Items == null || !request.Items.Any())
                return BadRequest("Đơn hàng rỗng.");

            // 1️⃣ CHECK KHO + LẤY GIÁ (1 LẦN)
            var checkStockRequest = request.Items.Select(i =>
                new CheckStockRequest
                {
                    ProductId = i.ProductId,
                    UnitId = i.UnitId,
                    Quantity = i.Quantity
                }).ToList();

            var stockResults =
                await _productService.CheckStockAsync(checkStockRequest);

            var notEnough =
                stockResults.FirstOrDefault(x => !x.IsEnough);

            if (notEnough != null)
                return BadRequest(
                    $"Sản phẩm ID {notEnough.ProductId} không đủ hàng.");

            // 2️⃣ TẠO ĐƠN
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
                var stock = stockResults.First(x =>
                    x.ProductId == item.ProductId);

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

            // 3️⃣ GHI NỢ
            if (request.PaymentMethod == "Debt")
            {
                _context.DebtLogs.Add(new DebtLog
                {
                    CustomerId = request.CustomerId,
                    StoreId = request.StoreId,
                    Amount = totalAmount,
                    Reason = $"Nợ đơn hàng {order.OrderCode}",
                    CreatedAt = DateTime.UtcNow
                });
            }

            // 4️⃣ LƯU ĐƠN
            order.Status = "Confirmed";
            _context.Orders.Add(order);
            await _context.SaveChangesAsync();

            // 5️⃣ TRỪ KHO (SAU KHI LƯU)
            foreach (var item in order.OrderItems)
            {
                await _productService.DeductStockAsync(
                    item.ProductId,
                    item.UnitId,
                    item.Quantity);
            }
            // 🔥 6️⃣ SIGNALR: BẮN THÔNG BÁO "TING TING" (PHẦN MỚI THÊM)
            // ==========================================================
            try 
            {
                // Gửi tin nhắn đến nhóm "Admins" (Những người đang mở trang Web Admin)
                await _hubContext.Clients.Group("Admins").SendAsync("ReceiveOrderNotification", new 
                { 
                    Message = $"🔔 Ting ting! Đơn mới {order.OrderCode}", 
                    TotalAmount = order.TotalAmount,
                    Time = DateTime.Now.ToString("HH:mm:ss")
                });
            }
            catch (Exception ex)
            {
                // Nếu lỗi SignalR thì chỉ log ra console, KHÔNG ĐƯỢC làm lỗi đơn hàng
                Console.WriteLine($"--> Lỗi gửi thông báo SignalR: {ex.Message}");
            }
            // ==========================================================
            return Ok(new
            {
                Message = "Tạo đơn thành công",
                OrderId = order.Id
            });
        }
    }
}
