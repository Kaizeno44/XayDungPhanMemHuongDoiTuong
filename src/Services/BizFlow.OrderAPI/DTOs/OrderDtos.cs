namespace BizFlow.OrderAPI.DTOs
{
    // 1. Dữ liệu Frontend gửi lên khi tạo đơn
    public class CreateOrderRequest
    {
        public Guid CustomerId { get; set; }   // ✅ Guid
        public Guid StoreId { get; set; }      // ✅ Guid

        public string PaymentMethod { get; set; } = string.Empty;

        public List<OrderItemDto> Items { get; set; } = new();
    }

    public class OrderItemDto
    {
        public int ProductId { get; set; }
        public int UnitId { get; set; }
        public int Quantity { get; set; }
    }

    // 2. Dữ liệu nhận về từ Product Service
    public class ProductPriceResponse
    {
        public decimal Price { get; set; }
        public string UnitName { get; set; } = string.Empty;
        public double ConversionValue { get; set; }
    }

    // 3. Dữ liệu trả về lịch sử đơn
    public class OrderHistoryDto
    {
        public Guid OrderId { get; set; }
        public string OrderCode { get; set; } = string.Empty;
        public DateTime OrderDate { get; set; }
        public decimal TotalAmount { get; set; }
        public string Status { get; set; } = string.Empty;
    }

    // DTO cho thông tin khách hàng (dùng khi lấy danh sách khách hàng)
    public class CustomerDto
    {
        public Guid Id { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string? PhoneNumber { get; set; }
        public string? Address { get; set; }
        public decimal CurrentDebt { get; set; }
        public Guid StoreId { get; set; }
    }

    // DTO wrapper để gửi danh sách yêu cầu kiểm tra tồn kho đến Product Service
    public class CheckStockRequestWrapperDto
    {
        public List<CheckStockRequest> Requests { get; set; } = new List<CheckStockRequest>();
    }

}
