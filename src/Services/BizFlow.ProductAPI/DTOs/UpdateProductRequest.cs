using System.Collections.Generic;

namespace BizFlow.ProductAPI.DTOs
{
    public class UpdateProductRequest
    {
        public int Id { get; set; }
        public required string Name { get; set; }
        public required string Sku { get; set; }
        public string? ImageUrl { get; set; }
        public string? Description { get; set; }
        public int CategoryId { get; set; }
        public bool IsActive { get; set; }
        public double? InitialStock { get; set; } // Thêm trường này để cập nhật tồn kho từ Web

        // Danh sách đơn vị tính và giá bán cập nhật
        public List<ProductUnitUpdateDto>? Units { get; set; }
    }

    public class ProductUnitUpdateDto
    {
        public int? Id { get; set; } // Nếu có Id là cập nhật, không có là thêm mới
        public required string UnitName { get; set; }
        public double ConversionValue { get; set; }
        public decimal Price { get; set; }
        public bool IsBaseUnit { get; set; }
    }
}
