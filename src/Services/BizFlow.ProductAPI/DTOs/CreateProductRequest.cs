using System.ComponentModel.DataAnnotations;

namespace BizFlow.ProductAPI.DTOs
{
    public class CreateProductRequest
    {
        [Required]
        public string Name { get; set; } = string.Empty;

        [Required]
        public string Sku { get; set; } = string.Empty;

        public int CategoryId { get; set; }

        public string? ImageUrl { get; set; }
        public string? Description { get; set; }

        // --- CÁC TRƯỜNG MỚI (Logic 4 bảng) ---

        [Required]
        public string BaseUnitName { get; set; } = string.Empty; // VD: Bao

        public decimal BasePrice { get; set; } // Giá bán lẻ

        public double InitialStock { get; set; } // Tồn kho ban đầu

        public List<ProductUnitDto> OtherUnits { get; set; } = new List<ProductUnitDto>();
    }

    public class ProductUnitDto
    {
        public string UnitName { get; set; } = string.Empty;
        public double ConversionValue { get; set; }
        public decimal Price { get; set; }
    }
}