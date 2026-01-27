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
        private readonly IConfiguration _configuration;

        public OrdersController(
            OrderDbContext context,
            ProductServiceClient productService,
            IHubContext<NotificationHub> hubContext,
            IPublishEndpoint publishEndpoint,
            IConfiguration configuration)
        {
            _context = context;
            _productService = productService;
            _hubContext = hubContext;
            _publishEndpoint = publishEndpoint;
            _configuration = configuration;
        }

        // ========================================================================
        // 1. LẤY DANH SÁCH ĐƠN HÀNG (CÓ LỌC THEO STORE)
        // ========================================================================
        [HttpGet]
        public async Task<IActionResult> GetOrders([FromQuery] Guid? storeId)
        {
            var query = _context.Orders.AsQueryable();

            // Nếu có storeId, chỉ lấy đơn của store đó
            if (storeId.HasValue)
            {
                query = query.Where(o => o.StoreId == storeId.Value);
            }

            var orders = await query
                .OrderByDescending(o => o.OrderDate)
                .Select(o => new
                {
                    o.Id,
                    o.OrderCode,
                    o.OrderDate,
                    o.TotalAmount,
                    o.Status,
                    o.PaymentMethod,
                    o.CustomerId,
                    // Lấy thêm tên khách hàng để hiển thị trên Web Admin
                    CustomerName = _context.Customers
                                    .Where(c => c.Id == o.CustomerId)
                                    .Select(c => c.FullName)
                                    .FirstOrDefault() ?? "Khách lẻ"
                })
                .ToListAsync();

            return Ok(orders);
        }

        // ========================================================================
        // 2. [QUAN TRỌNG] LẤY ĐƠN HÀNG CỦA 1 KHÁCH (CHO MOBILE APP)
        // ========================================================================
        [HttpGet("customer/{customerId}")]
        public async Task<IActionResult> GetOrdersByCustomer(Guid customerId)
        {
            var orders = await _context.Orders
                .Where(o => o.CustomerId == customerId)
                .OrderByDescending(o => o.OrderDate) // Đơn mới nhất lên đầu
                .Select(o => new
                {
                    o.Id,
                    o.OrderCode,
                    o.OrderDate,
                    o.TotalAmount,
                    o.Status,
                    o.PaymentMethod
                })
                .ToListAsync();

            return Ok(orders);
        }

        // ========================================================================
        // 3. CHI TIẾT ĐƠN HÀNG
        // ========================================================================
        [HttpGet("{id}")]
        public async Task<IActionResult> GetOrderById(Guid id)
        {
            var order = await _context.Orders
                .Where(o => o.Id == id)
                .Select(o => new
                {
                    o.Id,
                    o.OrderCode,
                    o.OrderDate,
                    o.TotalAmount,
                    o.Status,
                    o.PaymentMethod,
                    o.CustomerId,
                    o.StoreId,
                    CustomerName = _context.Customers
                                    .Where(c => c.Id == o.CustomerId)
                                    .Select(c => c.FullName)
                                    .FirstOrDefault() ?? "Khách lẻ",
                    OrderItems = o.OrderItems.Select(oi => new
                    {
                        oi.Id,
                        oi.ProductId,
                        oi.UnitId,
                        oi.Quantity,
                        oi.UnitPrice,
                        oi.Total
                    }).ToList()
                })
                .FirstOrDefaultAsync();

            if (order == null) return NotFound(new { message = "Không tìm thấy đơn hàng" });

            return Ok(order);
        }

        // ========================================================================
        // 4. TẠO ĐƠN HÀNG MỚI
        // ========================================================================
        [HttpPost]
        public async Task<IActionResult> CreateOrder([FromBody] CreateOrderRequest request)
        {
            // Validate sơ bộ
            if (request.Items == null || !request.Items.Any())
                return BadRequest("Đơn hàng rỗng.");

            // A. Kiểm tra tồn kho (Synchronous Fail-Fast)
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

            // B. Transaction DB
            using var transaction = await _context.Database.BeginTransactionAsync();

            try
            {
                // B1. Tạo Order Object
                var order = new Order
                {
                    OrderCode = $"ORD-{DateTime.Now:yyMMddHHmm}-{new Random().Next(100, 999)}", // Mã ngắn gọn hơn
                    CustomerId = request.CustomerId,
                    StoreId = request.StoreId,
                    OrderDate = DateTime.UtcNow,
                    PaymentMethod = request.PaymentMethod,
                    Status = "Confirmed", // Đặt luôn là Confirmed nếu đã qua bước check kho (hoặc Pending tùy logic)
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
                        UnitPrice = stock.UnitPrice, // Lấy giá từ Service trả về (chuẩn nhất)
                        Total = stock.UnitPrice * item.Quantity
                    };
                    order.OrderItems.Add(orderItem);
                    totalAmount += orderItem.Total;
                }
                order.TotalAmount = totalAmount;

                // B2. Xử lý Ghi nợ (Nếu chọn Trả sau)
                if (request.PaymentMethod == "Debt")
                {
                    // Check hạn mức
                    var currentDebt = await _context.DebtLogs
                        .Where(d => d.CustomerId == request.CustomerId)
                        .SumAsync(d => d.Action == "Debit" ? d.Amount : -d.Amount); // Tính tổng nợ thực tế (Debit - Credit)

                    // Config hạn mức
                    decimal creditLimit = _configuration.GetValue<decimal>("OrderSettings:CreditLimit", 50_000_000);

                    if (currentDebt + totalAmount > creditLimit)
                    {
                        return BadRequest($"Vượt hạn mức tín dụng. Hạn mức: {creditLimit:N0}, Hiện nợ: {currentDebt:N0}");
                    }

                    // Ghi log nợ
                    _context.DebtLogs.Add(new DebtLog
                    {
                        CustomerId = request.CustomerId,
                        StoreId = request.StoreId,
                        Amount = totalAmount,
                        Action = "Debit",
                        Reason = $"Nợ đơn hàng {order.OrderCode}",
                        CreatedAt = DateTime.UtcNow,
                        RefOrderId = order.Id
                    });

                    // Update số dư khách
                    var customer = await _context.Customers.FindAsync(request.CustomerId);
                    if (customer != null) customer.CurrentDebt += totalAmount;
                }

                // B3. Lưu xuống DB
                _context.Orders.Add(order);
                
                // B4. Bắn Event (MassTransit Outbox pattern)
                await _publishEndpoint.Publish(new OrderCreatedEvent
                {
                    OrderId = order.Id, // GUID sẽ được EF sinh ra hoặc gán trước khi Save
                    OrderCode = order.OrderCode,
                    StoreId = order.StoreId,
                    TotalAmount = order.TotalAmount,
                    CreatedAt = order.OrderDate,
                    OrderItems = request.Items.Select(x => new OrderItemEvent
                    {
                        ProductId = x.ProductId,
                        UnitId = x.UnitId,
                        Quantity = x.Quantity
                    }).ToList()
                });

                await _context.SaveChangesAsync(); // Lưu Order + DebtLog + Outbox Message
                await transaction.CommitAsync();

                // B5. Gửi thông báo Realtime
                await _hubContext.Clients.Group("Admins").SendAsync("ReceiveNotification", new
                {
                    title = "Đơn hàng mới! 🛒",
                    message = $"Đơn {order.OrderCode} - {order.TotalAmount:N0}đ",
                    orderId = order.Id
                });

                return Ok(new
                {
                    Message = "Tạo đơn thành công",
                    OrderId = order.Id,
                    OrderCode = order.OrderCode
                });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, $"Lỗi xử lý đơn hàng: {ex.Message}");
            }
        }

        // ========================================================================
        // 5. CẬP NHẬT TRẠNG THÁI
        // ========================================================================
        [HttpPut("{id}/status")]
        public async Task<IActionResult> UpdateOrderStatus(Guid id, [FromBody] string status)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null) return NotFound(new { message = "Không tìm thấy đơn hàng" });

            order.Status = status;
            await _context.SaveChangesAsync();

            return Ok(new { message = "Cập nhật trạng thái thành công", status = order.Status });
        }
    }
}