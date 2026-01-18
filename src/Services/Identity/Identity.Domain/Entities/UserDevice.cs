namespace Identity.Domain.Entities;

public class UserDevice
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; } // Token này của ông User nào
    public string DeviceToken { get; set; } = string.Empty; // Token FCM
    
    // 👇 Thêm 2 dòng này vào để khớp với UsersController
    public string Platform { get; set; } = "Android"; // Ví dụ: "Android", "iOS", "Web"
    public DateTime LastActiveAt { get; set; } = DateTime.UtcNow; // Thời điểm cuối cùng online
}