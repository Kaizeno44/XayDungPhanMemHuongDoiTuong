using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BizFlow.ProductAPI.DbModels
{
    [Table("Products")]
    public class Product
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public string Name { get; set; } = string.Empty;

        [Required]
        public string Sku { get; set; } = string.Empty;

        public string? ImageUrl { get; set; }
        public string? Description { get; set; }

        public int CategoryId { get; set; }
        [ForeignKey("CategoryId")]
        public Category Category { get; set; }

        public string BaseUnit { get; set; } = string.Empty;

        // --- LIÊN KẾT BẢNG ---
        // 1 Sản phẩm có 1 thông tin kho
        public Inventory Inventory { get; set; } 

        // 1 Sản phẩm có nhiều đơn vị tính
        public ICollection<ProductUnit> ProductUnits { get; set; } = new List<ProductUnit>();
    }
}