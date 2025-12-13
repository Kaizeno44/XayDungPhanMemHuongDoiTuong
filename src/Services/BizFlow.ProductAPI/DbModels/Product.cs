using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BizFlow.ProductAPI.DbModels
{
    [Table("Products")]
    public class Product
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("Category")]
        public int CategoryId { get; set; }

        [Required]
        [MaxLength(200)]
        public string Name { get; set; } = string.Empty;

        [MaxLength(50)]
        public string Sku { get; set; } = string.Empty; // Mã vạch

        [Required]
        [MaxLength(20)]
        public string BaseUnit { get; set; } = string.Empty; // Đơn vị gốc (VD: Cái)

        public decimal StockQuantity { get; set; } = 0; // Tồn kho theo BaseUnit

        public bool IsActive { get; set; } = true;

        // Navigation Properties (Để nối bảng)
        public Category Category { get; set; } = null!;
        public ICollection<ProductUnit> ProductUnits { get; set; } = new List<ProductUnit>();
        public Inventory Inventory { get; set; } = null!;
        [Column(TypeName = "decimal(18,2)")]
        public decimal Price { get; set; }
    }
}