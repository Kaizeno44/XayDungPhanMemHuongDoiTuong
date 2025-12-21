namespace BizFlow.ProductAPI.DTOs
{
    // Gói tin bên Order gửi sang hỏi
    public class CheckStockRequest
    {
        public int ProductId { get; set; }
        public int UnitId { get; set; } // Mua theo đơn vị nào (VD: Tấn)
        public double Quantity { get; set; } // Số lượng muốn mua
    }

    // Gói tin Kho trả lời
    public class CheckStockResult
    {
        public int ProductId { get; set; }
        public bool IsEnough { get; set; } // Đủ hàng hay không
        public string Message { get; set; }= string.Empty; // Lý do (VD: Chỉ còn 40 Bao)
    }
}