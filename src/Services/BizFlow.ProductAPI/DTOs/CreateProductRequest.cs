using System.Collections.Generic;

namespace BizFlow.ProductAPI.DTOs
{
    public class CreateProductRequest
    {
        public required string Name { get; set; }
        public required string Sku { get; set; }
        public required string ImageUrl { get; set; }
        public required string Description { get; set; }
        public int CategoryId { get; set; }
        
        // Đơn vị tính gốc (ví dụ: Viên, Cái)
        public required string BaseUnitName { get; set; }
        public int InitialStock { get; set; }
        public decimal BasePrice { get; set; }
        
        // Danh sách đơn vị quy đổi (ví dụ: Thùng, Hộp)
        public List<ProductUnitDto>? OtherUnits { get; set; }
    }

    public class ProductUnitDto
    {
        public required string UnitName { get; set; }
        public double ConversionValue { get; set; }
        public decimal Price { get; set; }
    }
}