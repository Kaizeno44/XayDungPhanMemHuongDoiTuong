using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BizFlow.OrderAPI.DbModels
{
    [Table("DebtLogs")]
    public class DebtLog
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid CustomerId { get; set; }
    public Customer Customer { get; set; } = null!; // ✅ ADD

    public Guid StoreId { get; set; }

    public Guid? RefOrderId { get; set; }
    public Order? Order { get; set; }   // ✅ ADD

    public decimal Amount { get; set; }
    public string Action { get; set; } = "Debit";
    public string Reason { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

}
