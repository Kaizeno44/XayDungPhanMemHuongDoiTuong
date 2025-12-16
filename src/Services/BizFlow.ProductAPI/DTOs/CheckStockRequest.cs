namespace BizFlow.ProductAPI.DTOs
{
    // Món hàng cần kiểm tra
    public class CheckStockItem
    {
        public int ProductId { get; set; }
        public int UnitId { get; set; } // Mua theo đơn vị nào (Bao/Tấn)
        public decimal Quantity { get; set; } // Số lượng muốn mua
    }

    // Kết quả trả về cho từng món
    public class CheckStockResult
    {
        public int ProductId { get; set; }
        public bool IsAvailable { get; set; } // Có đủ hàng không?
        public decimal UnitPrice { get; set; } // Giá tiền của đơn vị đó (để bên C tính tiền)
        public string Message { get; set; } = string.Empty; // Lỗi nếu có
    }
}