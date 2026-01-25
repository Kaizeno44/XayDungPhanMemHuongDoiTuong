using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BizFlow.ProductAPI.DbModels
{
    [Table("Products")]
    public class Product
    {
        [Key]
        public int Id { get; set; }
        public Guid StoreId { get; set; }
        public int CategoryId { get; set; }
        [ForeignKey("CategoryId")]
        public Category Category { get; set; }

        [Required, MaxLength(200)]
        public string Name { get; set; } = string.Empty; // VD: Xi măng Hà Tiên

        [Required, MaxLength(50)]
        public string Sku { get; set; } = string.Empty; // VD: XM_HT_01

        public string BaseUnit { get; set; } = string.Empty; // VD: Kg (Đơn vị gốc để tính kho)

        public string? ImageUrl { get; set; }
        public string? Description { get; set; }
        
        public bool IsActive { get; set; } = true; // 👈 Mới thêm

        // --- LIÊN KẾT ---
        public Inventory Inventory { get; set; } 
        public ICollection<ProductUnit> ProductUnits { get; set; } = new List<ProductUnit>();
    }
}