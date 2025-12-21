using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BizFlow.ProductAPI.DbModels
{
    [Table("ProductUnits")]
    public class ProductUnit
    {
        [Key]
        public int Id { get; set; }

        public int ProductId { get; set; }
        [ForeignKey("ProductId")]
        [System.Text.Json.Serialization.JsonIgnore]
        public Product Product { get; set; }

        [Required, MaxLength(50)]
        public string UnitName { get; set; } = string.Empty; // VD: Bao

        public double ConversionValue { get; set; } = 1; // VD: 50 (1 Bao = 50 Kg)

        [Column(TypeName = "decimal(18,2)")]
        public decimal Price { get; set; } // VD: 90.000 (Giá bán của đơn vị này)

        public bool IsBaseUnit { get; set; } = false; // Đánh dấu nếu là đơn vị gốc
    }
}