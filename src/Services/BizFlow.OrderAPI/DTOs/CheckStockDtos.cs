namespace BizFlow.OrderAPI.DTOs
{
    // Request gửi sang ProductAPI
    public class CheckStockRequest
    {
        public int ProductId { get; set; }
        public int UnitId { get; set; }
        public int Quantity { get; set; }
    }

    // Response nhận về từ ProductAPI
    public class CheckStockResult
    {
        public int ProductId { get; set; }
        public int UnitId { get; set; }
        public bool IsEnough { get; set; } // Quan trọng: True nếu đủ hàng
        public decimal UnitPrice { get; set; } // Giá bán tại thời điểm check
        public string ProductName { get; set; } = string.Empty;
    }
}