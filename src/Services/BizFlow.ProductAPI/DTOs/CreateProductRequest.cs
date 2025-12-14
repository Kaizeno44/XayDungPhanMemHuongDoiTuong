namespace BizFlow.ProductAPI.DTOs
{
    public class ProductUnitDto
    {
        // Thêm = string.Empty để đảm bảo không bao giờ null
        public string UnitName { get; set; } = string.Empty; 
        
        public int ConversionRate { get; set; }
        public decimal Price { get; set; }
        public bool IsDefault { get; set; }
    }

    public class CreateProductRequest
    {
        // Thêm = string.Empty
        public string Name { get; set; } = string.Empty;
        
        // Thêm = string.Empty
        public string BaseUnit { get; set; } = string.Empty;
        
        public int CategoryId { get; set; }

        // Quan trọng: Khởi tạo List luôn để tránh lỗi NullReference khi lặp
        public List<ProductUnitDto> Units { get; set; } = new List<ProductUnitDto>();
    }

    public class DeductStockRequest
    {
        public int UnitId { get; set; }
        public decimal Quantity { get; set; }
    }
}