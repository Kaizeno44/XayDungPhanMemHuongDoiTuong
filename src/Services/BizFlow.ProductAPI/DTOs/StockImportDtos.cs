namespace BizFlow.ProductAPI.DTOs
{
    // Class chi tiết cho từng sản phẩm trong phiếu
    public class StockImportDetailDto
    {
        public int ProductId { get; set; }
        public int UnitId { get; set; }
        public double Quantity { get; set; }
        public double UnitCost { get; set; } // Mobile gửi key là "unitCost"
    }

    // Class chính hứng payload từ Mobile
    public class CreateStockImportRequest
    {
        public Guid StoreId { get; set; }
        public string? Note { get; set; }        // Mobile gửi "notes", JSON parser tự map sang Note/Notes
        public string? SupplierName { get; set; }
        
        // Danh sách chi tiết nhập kho
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