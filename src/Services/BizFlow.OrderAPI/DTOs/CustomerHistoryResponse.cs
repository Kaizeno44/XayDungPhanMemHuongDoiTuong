
public class CustomerHistoryResponse
{
    public Guid CustomerId { get; set; }
    public decimal CurrentDebt { get; set; }
    public int OrderCount { get; set; }
    public List<OrderHistoryItemDto> Orders { get; set; } = new();
}

public class OrderHistoryItemDto
{
    public Guid Id { get; set; }
    public string OrderCode { get; set; } = string.Empty;
    public decimal TotalAmount { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime OrderDate { get; set; }
    public string PaymentMethod { get; set; } = string.Empty;
}
