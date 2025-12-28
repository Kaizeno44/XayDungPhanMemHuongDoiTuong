using Microsoft.AspNetCore.SignalR;

namespace BizFlow.OrderAPI.Hubs
{
    // Đây là cái loa phát thanh
    public class NotificationHub : Hub
    {
        // Hàm này để Web Admin gọi lên: "Tôi đã online, hãy gửi tin cho tôi"
        public async Task JoinAdminGroup()
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, "Admins");
            Console.WriteLine($"--> Admin connected: {Context.ConnectionId}");
        }
    }
}