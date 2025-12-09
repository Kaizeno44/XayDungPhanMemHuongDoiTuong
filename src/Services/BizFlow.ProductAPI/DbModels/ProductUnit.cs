using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BizFlow.ProductAPI.DbModels
{
    [Table("ProductUnits")]
    public class ProductUnit
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("Product")]
        public int ProductId { get; set; }

        [Required]
        [MaxLength(20)]
        public string UnitName { get; set; } = string.Empty; // VD: Thùng, Bao

        // QUAN TRỌNG: Tỷ lệ quy đổi (VD: 24)
        public int ConversionRate { get; set; } = 1; 

        public decimal Price { get; set; } = 0; // Giá bán theo đơn vị này

        public bool IsDefault { get; set; } = false;

        // Nối ngược về Product
        public Product Product { get; set; } = null!;
    }
}