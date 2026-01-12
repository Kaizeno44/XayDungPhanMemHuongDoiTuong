using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BizFlow.ProductAPI.DbModels
{
    [Table("StockImports")]
    public class StockImport
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int ProductId { get; set; }
        [ForeignKey("ProductId")]
        public Product Product { get; set; }

        [Required]
        public int UnitId { get; set; }
        [ForeignKey("UnitId")]
        public ProductUnit Unit { get; set; }

        [Required]
        public double Quantity { get; set; }

        [Required]
        public double CostPrice { get; set; } // Giá vốn nhập vào

        public string? SupplierName { get; set; } // Nhà cung cấp

        public DateTime ImportDate { get; set; } = DateTime.UtcNow;

        public string? Note { get; set; }
        
        public Guid StoreId { get; set; } // Thuộc về cửa hàng nào
    }
}
