using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BizFlow.ProductAPI.DbModels
{
    [Table("Inventories")]
    public class Inventory
    {
        [Key]
        [ForeignKey("Product")]
        public int ProductId { get; set; } // Khóa chính cũng là khóa ngoại

        public decimal Quantity { get; set; } = 0;

        public decimal MinStockLevel { get; set; } = 10; // Cảnh báo khi sắp hết

        public DateTime LastUpdated { get; set; } = DateTime.UtcNow;

        // Nối về Product
        public Product Product { get; set; } = null!;
    }
}