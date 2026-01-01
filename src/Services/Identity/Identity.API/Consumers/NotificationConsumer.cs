using FirebaseAdmin.Messaging;
using MassTransit;
using Shared.Kernel.Events;
using Identity.API.Data;
using Microsoft.EntityFrameworkCore;

namespace Identity.API.Consumers;

// 1. IConsumer<OrderCreatedEvent>: Đây là "Hợp đồng làm việc".
// Nó bảo rằng: "Class này chuyên xử lý sự kiện OrderCreatedEvent"
// Hễ RabbitMQ có tin nhắn loại này, nó sẽ chuyển cho class này xử lý.
public class NotificationConsumer : IConsumer<OrderCreatedEvent>
{
    private readonly AppDbContext _context;
    private readonly ILogger<NotificationConsumer> _logger;

    // Inject DbContext để lát nữa tra cứu Database tìm DeviceToken
    public NotificationConsumer(AppDbContext context, ILogger<NotificationConsumer> logger)
    {
        _context = context;
        _logger = logger;
    }

    // 2. Hàm Consume: Đây là nơi xử lý chính.
    // Khi có tin nhắn đến, hàm này tự động được kích hoạt.
    public async Task Consume(ConsumeContext<OrderCreatedEvent> context)
    {
        // Lấy nội dung tin nhắn ra (Thông tin đơn hàng ông C vừa gửi)
        var msg = context.Message;
        
        _logger.LogInformation($"[🔔] Có đơn mới! Mã đơn: {msg.OrderId}, Tiền: {msg.TotalAmount}");

        // --- PHẦN LOGIC TÌM NGƯỜI NHẬN ---
        
        // Bước A: Đơn hàng này của Store nào? -> Tìm ông chủ Store đó (User)
        var owner = await _context.Users
            .Where(u => u.StoreId == msg.StoreId) 
            .FirstOrDefaultAsync();

        if (owner == null) return; // Không tìm thấy chủ thì thôi

        // Bước B: Ông chủ này đang dùng điện thoại gì? (Lấy Token trong bảng UserDevices)
        // Bảng này lưu: User A dùng iPhone (Token123), dùng Android (Token456)...
        var deviceTokens = await _context.UserDevices
            .Where(d => d.UserId == owner.Id)
            .Select(d => d.DeviceToken)
            .ToListAsync();

        if (deviceTokens.Count == 0)
        {
            _logger.LogWarning("Ông chủ này chưa cài App nên không có Token để gửi.");
            return;
        }

        // --- PHẦN GỬI THÔNG BÁO ---

        // Bước C: Gửi thông báo đến từng thiết bị của ông chủ
        foreach (var token in deviceTokens)
        {
            // Tạo nội dung thông báo
            var message = new Message()
            {
                Token = token, // Gửi đến địa chỉ này
                Notification = new Notification()
                {
                    Title = "Tinh ting! Đơn hàng mới 💰",
                    Body = $"Khách vừa chốt đơn {msg.TotalAmount:N0}đ. Vào check ngay!"
                },
                // Gửi kèm dữ liệu ẩn để App xử lý (ví dụ bấm vào nhảy đúng đơn hàng đó)
                Data = new Dictionary<string, string>()
                {
                    { "orderId", msg.OrderId.ToString() },
                    { "type", "new_order" }
                }
            };

            // Gọi Google Firebase để bắn đi
            try 
            {
                await FirebaseMessaging.DefaultInstance.SendAsync(message);
                _logger.LogInformation($"--> Đã gửi xong tới thiết bị đuôi ...{token[^5..]}");
            }
            catch (Exception ex)
            {
                // Token hết hạn hoặc App bị xóa thì sẽ lỗi, ta log lại thôi
                _logger.LogError($"Gửi lỗi: {ex.Message}");
            }
        }
    }
}