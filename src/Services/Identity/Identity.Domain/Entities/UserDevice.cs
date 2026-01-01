namespace Identity.Domain.Entities;

public class UserDevice
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; } // Token này của ông User nào
    public string DeviceToken { get; set; } = string.Empty; // Token FCM
    public DateTime LastUpdated { get; set; } = DateTime.UtcNow;
}