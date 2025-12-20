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
        [System.Text.Json.Serialization.JsonIgnore] // Tránh vòng lặp JSON
        public Product Product { get; set; }

        [Required]
        public string UnitName { get; set; } = string.Empty; // VD: Bao, Tấn, Xe

        public double ConversionValue { get; set; } = 1; // Quy đổi: 1 Tấn = 20 Bao
        
        public bool IsBaseUnit { get; set; } = false; // Đơn vị gốc?

        [Column(TypeName = "decimal(18,2)")]
        public decimal Price { get; set; } // 💰 GIÁ TIỀN NẰM Ở ĐÂY
    }
}