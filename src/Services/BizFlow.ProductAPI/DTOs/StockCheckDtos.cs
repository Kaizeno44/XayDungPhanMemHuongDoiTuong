namespace BizFlow.ProductAPI.DTOs
{
    // Dữ liệu ông C gửi sang để hỏi kho
    public class CheckStockRequest
    {
        public int ProductId { get; set; }
        public int UnitId { get; set; } // ID của đơn vị (ví dụ: Mua theo Tấn hay theo Bao)
        public int Quantity { get; set; } // Số lượng khách mua
    }

    // Kết quả mình trả về cho ông C
    public class CheckStockResult
    {
        public int ProductId { get; set; }
        public bool IsEnough { get; set; } // True = Đủ hàng
        public string Message { get; set; }
        public decimal UnitPrice { get; set; } // Kèm giá luôn để bên kia khỏi hỏi lại
    }

    // DTO wrapper để nhận danh sách yêu cầu kiểm tra tồn kho
    public class CheckStockRequestWrapperDto
    {
        public List<CheckStockRequest> Requests { get; set; } = new List<CheckStockRequest>();
    }

    // DTO đơn giản cho kết quả kiểm tra tồn kho (dùng cho mobile)
    public class SimpleCheckStockResultDto
    {
        public bool IsEnough { get; set; }
        public string Message { get; set; }
    }
}
