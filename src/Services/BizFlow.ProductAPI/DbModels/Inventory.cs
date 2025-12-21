using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BizFlow.ProductAPI.DbModels
{
    [Table("Inventories")]
    public class Inventory
    {
        [Key]
        public int Id { get; set; }

        public int ProductId { get; set; }
        
        [ForeignKey("ProductId")]
        [System.Text.Json.Serialization.JsonIgnore]
        public Product Product { get; set; }

        // ⚠️ QUAN TRỌNG: Phải là double để khớp với DTO và tính toán
        public double Quantity { get; set; } = 0; 

        public DateTime LastUpdated { get; set; } = DateTime.UtcNow;
    }
}