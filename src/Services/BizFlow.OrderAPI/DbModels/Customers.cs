using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BizFlow.OrderAPI.DbModels
{
    [Table("Customers")]
    public class Customer
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid StoreId { get; set; }

    [Required]
    public string FullName { get; set; } = string.Empty;

    public string PhoneNumber { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public decimal CurrentDebt { get; set; } = 0;

    // ✅ ADD
    public ICollection<Order> Orders { get; set; } = new List<Order>();
    public ICollection<DebtLog> DebtLogs { get; set; } = new List<DebtLog>();
}

}