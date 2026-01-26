namespace BizFlow.ProductAPI.DTOs
{
    // 1. DTO cho từng sản phẩm trong danh sách nhập
    public class StockImportDetailDto
    {
        public int ProductId { get; set; }
        public int UnitId { get; set; }
        public double Quantity { get; set; }
        public double UnitCost { get; set; } // Mobile gửi là unitCost, map sang CostPrice
    }

    // 2. DTO bao bọc (Wrapper) nhận toàn bộ payload từ Mobile
    public class CreateStockImportRequest
    {
        public Guid StoreId { get; set; }
        public string? Notes { get; set; } // Mobile gửi là notes
        public string? SupplierName { get; set; }
        
        // Danh sách chi tiết
        public List<StockImportDetailDto> Details { get; set; } = new();
    }

    // 3. DTO Phản hồi (Giữ nguyên hoặc mở rộng nếu cần)
    public class StockImportResponse
    {
        public int Id { get; set; }
        public string ProductName { get; set; }
        public string UnitName { get; set; }
        public double Quantity { get; set; }
        public double CostPrice { get; set; }
        public double TotalCost => Quantity * CostPrice;
        public string? SupplierName { get; set; }
        public DateTime ImportDate { get; set; }
        public string? Note { get; set; }
    }
}