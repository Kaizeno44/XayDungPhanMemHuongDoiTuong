using BizFlow.OrderAPI.Data;
using BizFlow.OrderAPI.DbModels;
using BizFlow.OrderAPI.DTOs;
using BizFlow.OrderAPI.Services;
using MassTransit;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Shared.Kernel.Events;

namespace BizFlow.OrderAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class OrdersController : ControllerBase
    {
        private readonly OrderDbContext _context;
        private readonly ProductServiceClient _productService;
        private readonly IPublishEndpoint _publishEndpoint;
        private readonly IConfiguration _configuration; // [New] Để đọc config

        public OrdersController(
            OrderDbContext context,
            ProductServiceClient productService,
            IPublishEndpoint publishEndpoint,
            IConfiguration configuration)
        {
            _context = context;
            _productService = productService;
            _publishEndpoint = publishEndpoint;
            _configuration = configuration;
        }

        [HttpPost]
        public async Task<IActionResult> CreateOrder([FromBody] CreateOrderRequest request)
        {
            // 1. Validate
            if (request.Items == null || !request.Items.Any())
                return BadRequest("Đơn hàng rỗng.");

            // =================================================================
            // 2. FAIL-FAST VALIDATION (Synchronous)
            // =================================================================
            // Kiểm tra kho trước để báo lỗi ngay cho UI nếu hết hàng (User Experience tốt hơn)
            var checkStockRequest = request.Items.Select(i => new CheckStockRequest
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
            // 3. XÂY DỰNG ĐƠN HÀNG (Domain Logic)
            // =================================================================
            // Sử dụng Transaction của EF Core để đảm bảo tính toàn vẹn (Atomicity)
            // Đặc biệt quan trọng khi dùng Outbox Pattern
            using var transaction = await _context.Database.BeginTransactionAsync();

            try
            {
                var order = new Order
                {
                    OrderCode = $"ORD-{DateTime.Now:yyyyMMddHHmmss}-{new Random().Next(100, 999)}", // Thêm Random để tránh trùng giây
                    CustomerId = request.CustomerId,
                    StoreId = request.StoreId,
                    OrderDate = DateTime.UtcNow,
                    PaymentMethod = request.PaymentMethod,
                    Status = "Pending", // Trạng thái ban đầu luôn là Pending
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
                // 4. KIỂM TRA HẠN MỨC CÔNG NỢ
                // =================================================================
                if (request.PaymentMethod == "Debt")
                {
                    var currentDebt = await _context.DebtLogs
                        .Where(d => d.CustomerId == request.CustomerId)
                        .SumAsync(d => d.Amount);

                    // Lấy hạn mức từ Config thay vì Hardcode
                    decimal creditLimit = _configuration.GetValue<decimal>("OrderSettings:CreditLimit", 50_000_000);

                    if (currentDebt + totalAmount > creditLimit)
                    {
                        return BadRequest($"Vượt hạn mức tín dụng. Hạn mức: {creditLimit:N0}, Hiện nợ: {currentDebt:N0}, Đơn mới: {totalAmount:N0}");
                    }

                    _context.DebtLogs.Add(new DebtLog
                    {
                        CustomerId = request.CustomerId,
                        StoreId = request.StoreId,
                        Amount = totalAmount,
                        Action = "Debit",
                        Reason = $"Nợ đơn hàng {order.OrderCode}",
                        CreatedAt = DateTime.UtcNow
                    });

                    var customer = await _context.Customers.FindAsync(request.CustomerId);
                    if (customer != null) customer.CurrentDebt += totalAmount;
                }

                // =================================================================
                // 5. SAVE & PUBLISH (TRANSACTIONAL OUTBOX)
                // =================================================================
                _context.Orders.Add(order);
                
                // LƯU Ý QUAN TRỌNG: 
                // Khi dùng MassTransit Transactional Outbox (cần config trong Program.cs),
                // Lệnh Publish này KHÔNG gửi ngay lập tức. Nó chỉ lưu message vào bảng "OutboxMessage" trong DB.
                // Khi SaveChangesAsync thành công, MassTransit mới lấy message ra gửi đi.
                await _publishEndpoint.Publish(new OrderCreatedEvent
                {
                    OrderId = order.Id, // Lưu ý: Id có thể chưa có nếu dùng Identity Column chưa Save, nên dùng Guid hoặc OrderCode
                    OrderCode = order.OrderCode, // Nên truyền thêm OrderCode
                    StoreId = order.StoreId,
                    TotalAmount = order.TotalAmount,
                    CreatedAt = order.OrderDate,
                    OrderItems = request.Items.Select(x => new OrderItemEvent // Nên truyền chi tiết item để bên kia trừ kho
                    {
                        ProductId = x.ProductId,
                        UnitId = x.UnitId,
                        Quantity = x.Quantity
                    }).ToList()
                });

                // SaveChanges sẽ lưu cả Order, DebtLog VÀ Outbox Message trong 1 Transaction
                await _context.SaveChangesAsync(); 
                
                await transaction.CommitAsync();

                // =================================================================
                // 6. REMOVED: DEDUCT STOCK MANUAL
                // =================================================================
                // Đã xóa đoạn gọi _productService.DeductStockAsync.
                // Việc trừ kho bây giờ hoàn toàn phụ thuộc vào RabbitMQ Consumer.

                return Ok(new
                {
                    Message = "Đơn hàng đã được tiếp nhận", // Đổi thông báo cho chính xác nghĩa Async
                    OrderId = order.Id,
                    OrderCode = order.OrderCode
                });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                // Log error here
                return StatusCode(500, $"Lỗi xử lý đơn hàng: {ex.Message}");
            }
        }
    }
}