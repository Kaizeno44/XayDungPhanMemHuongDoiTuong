namespace BizFlow.OrderAPI.DTOs
{
    public class CustomerHistoryResponse
    {
        public Guid CustomerId { get; set; }
        public decimal CurrentDebt { get; set; }
        public int OrderCount { get; set; }
        public List<OrderHistoryItemDto> Orders { get; set; } = new();
        
        // 👇 BỔ SUNG: Danh sách lịch sử nợ cho tab "Lịch sử Nợ"
        public List<DebtLogDto> DebtHistory { get; set; } = new(); 
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

    // 👇 BỔ SUNG: DTO cho từng dòng lịch sử nợ
    public class DebtLogDto
    {
        public Guid Id { get; set; }
        public DateTime CreatedAt { get; set; }
        public decimal Amount { get; set; }
        public string Action { get; set; } = string.Empty; // "Debit" (Ghi nợ) hoặc "Credit" (Trả nợ)
        public string Reason { get; set; } = string.Empty; // Lý do: "Đơn hàng #...", "Trả nợ..."
        public Guid? RefOrderId { get; set; } // Để link sang đơn hàng nếu cần
    }
}