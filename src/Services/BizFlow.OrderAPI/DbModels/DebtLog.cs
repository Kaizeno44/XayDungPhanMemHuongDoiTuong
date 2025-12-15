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
        public Guid? RefOrderId { get; set; }
        public decimal Amount { get; set; } 
        public string Action { get; set; } = "Debit"; 
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public string Note { get; set; } = string.Empty;
    }
}