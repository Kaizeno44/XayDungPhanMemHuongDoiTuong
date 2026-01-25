public class CashBookItemDto
{
    public Guid Id { get; set; }
    public Guid CustomerId { get; set; }
    public string CustomerName { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Type { get; set; } = string.Empty; // "Order" hoặc "DebtRepayment"
    public string Action { get; set; } = string.Empty; // "Thu tiền", "Ghi nợ"
    public string Reason { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

public class RevenueStatDto
{
    public string Date { get; set; } = string.Empty;
    public decimal Revenue { get; set; }
}