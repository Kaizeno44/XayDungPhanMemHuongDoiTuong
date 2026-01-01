namespace Shared.Kernel.Events;

public record OrderCreatedEvent
{
    public Guid OrderId { get; init; }
    public Guid StoreId { get; init; }
    public decimal TotalAmount { get; init; }
    public DateTime CreatedAt { get; init; }
}