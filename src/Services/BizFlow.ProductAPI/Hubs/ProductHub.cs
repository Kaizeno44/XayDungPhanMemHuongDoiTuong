using Microsoft.AspNetCore.SignalR;

namespace BizFlow.ProductAPI.Hubs
{
    public class ProductHub : Hub
    {
        // Hub này sẽ được sử dụng để phát sóng các cập nhật tồn kho
        // Không cần logic cụ thể ở đây trừ khi bạn muốn client gọi các phương thức trên hub
        // Chúng ta sẽ phát sóng từ Controller
    }
}
