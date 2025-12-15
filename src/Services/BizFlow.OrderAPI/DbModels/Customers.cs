using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BizFlow.OrderAPI.DbModels
{
    [Table("Customers")]
    public class Customer
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        // 👇 QUAN TRỌNG: ID Cửa hàng (Multi-tenancy)
        // Bỏ dấu ? để bắt buộc mọi khách hàng phải thuộc về 1 cửa hàng
        public Guid StoreId { get; set; }

        [Required]
        public string FullName { get; set; } = string.Empty;
        
        public string PhoneNumber { get; set; } = string.Empty;
        
        public string Address { get; set; } = string.Empty;
        
        public decimal CurrentDebt { get; set; } = 0;
    }
}