using MassTransit;
using Shared.Kernel.Events;
using BizFlow.ProductAPI.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.SignalR; // [1] Thêm thư viện SignalR
using BizFlow.ProductAPI.Hubs;      // [2] Thêm namespace chứa ProductHub

namespace BizFlow.ProductAPI.Consumers
{
    public class OrderCreatedConsumer : IConsumer<OrderCreatedEvent>
    {
        private readonly ProductDbContext _context;
        private readonly ILogger<OrderCreatedConsumer> _logger;
        private readonly IHubContext<ProductHub> _hubContext; // [3] Inject HubContext

        public OrderCreatedConsumer(
            ProductDbContext context, 
            ILogger<OrderCreatedConsumer> logger,
            IHubContext<ProductHub> hubContext) // [4] Inject vào Constructor
        {
            _context = context;
            _logger = logger;
            _hubContext = hubContext;
        }

        public async Task Consume(ConsumeContext<OrderCreatedEvent> context)
        {
            var message = context.Message;
            _logger.LogInformation($"[RabbitMQ] Nhận sự kiện đơn hàng: {message.OrderCode}");

            foreach (var item in message.OrderItems)
            {
                var inventory = await _context.Inventories
                    .FirstOrDefaultAsync(i => i.ProductId == item.ProductId);

                if (inventory != null)
                {
                    // 1. Trừ kho trong DB
                    inventory.Quantity -= (double)item.Quantity;
                    inventory.LastUpdated = DateTime.UtcNow;
                    
                    _logger.LogInformation($"--> Trừ kho SP {item.ProductId}: Còn {inventory.Quantity}");

                    // 2. 🔥 BẮN SIGNALR REAL-TIME 🔥
                    // Gửi tin nhắn "ReceiveStockUpdate" để Mobile App cập nhật UI ngay lập tức
                    await _hubContext.Clients.All.SendAsync(
                        "ReceiveStockUpdate", 
                        item.ProductId, 
                        inventory.Quantity
                    );
                }
            }

            await _context.SaveChangesAsync();
        }
    }
}