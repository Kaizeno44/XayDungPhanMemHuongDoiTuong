using System.ComponentModel.DataAnnotations;

namespace BizFlow.OrderAPI.DbModels
{
    public class Order
    {
        [Key]
        public int Id { get; set; }
        public string OrderCode { get; set; } = string.Empty;
        public double TotalAmount { get; set; }
        public string Status { get; set; } = "Pending";
        public DateTime OrderDate { get; set; } = DateTime.UtcNow;
        public string PaymentMethod { get; set; } = "Cash";

        public Guid? CustomerId { get; set; }
        public Guid StoreId { get; set; }

        // 👇 QUAN TRỌNG: Thêm dòng này để link với OrderItem
        public ICollection<OrderItem> Items { get; set; } = new List<OrderItem>();
    }
}