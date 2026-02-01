using MassTransit;
using Shared.Kernel.Events;
using Microsoft.AspNetCore.SignalR;
using BizFlow.OrderAPI.Hubs;

namespace BizFlow.OrderAPI.Consumers
{
    public class OrderNotificationConsumer : IConsumer<OrderCreatedEvent>
    {
        private readonly IHubContext<NotificationHub> _hubContext;
        private readonly ILogger<OrderNotificationConsumer> _logger;

        public OrderNotificationConsumer(IHubContext<NotificationHub> hubContext, ILogger<OrderNotificationConsumer> logger)
        {
            _hubContext = hubContext;
            _logger = logger;
        }

        public async Task Consume(ConsumeContext<OrderCreatedEvent> context)
        {
            var orderEvent = context.Message;
            _logger.LogInformation($"--> OrderCreatedEvent received for OrderId: {orderEvent.OrderId}, OrderCode: {orderEvent.OrderCode}");

            // Gửi thông báo đến tất cả các client kết nối với NotificationHub
            // Hoặc gửi đến một nhóm cụ thể nếu có thông tin StoreId trong event
            await _hubContext.Clients.All.SendAsync("ReceiveOrderNotification", new
            {
                orderEvent.OrderId,
                orderEvent.OrderCode,
                orderEvent.StoreId,
                orderEvent.TotalAmount,
                orderEvent.CreatedAt,
                Message = $"Đơn hàng mới: {orderEvent.OrderCode} từ cửa hàng {orderEvent.StoreId} với tổng tiền {orderEvent.TotalAmount} đã được tạo!"
            });

            _logger.LogInformation($"--> Order notification sent for OrderCode: {orderEvent.OrderCode}");
        }
    }
}
