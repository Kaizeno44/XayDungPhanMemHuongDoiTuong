using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BizFlow.OrderAPI.DbModels
{
    [Table("Orders")]
    public class Order
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();
        public Guid StoreId { get; set; }
        public Guid CustomerId { get; set; }
        public DateTime OrderDate { get; set; } = DateTime.UtcNow;
        public decimal TotalAmount { get; set; }
        public string Status { get; set; } = "Draft"; 
        
        public Customer Customer { get; set; } = null!;
        
        // 👇 QUAN TRỌNG: Phải có đoạn " = new List<OrderItem>();" ở cuối
        public ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();
    }
}