using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BizFlow.OrderAPI.DbModels
{
    [Table("Orders")]
    public class Order
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        public string OrderCode { get; set; } = string.Empty;

        public Guid StoreId { get; set; }
        public Guid CustomerId { get; set; }

        public DateTime OrderDate { get; set; }
        public decimal TotalAmount { get; set; }

        public string Status { get; set; } = "Draft";
        public string PaymentMethod { get; set; } = string.Empty;

        public ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();
    }
}
