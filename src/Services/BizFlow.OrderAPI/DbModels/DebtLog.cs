using System.ComponentModel.DataAnnotations;

namespace BizFlow.OrderAPI.DbModels
{
    public class DebtLog
    {
        [Key]
        public Guid Id { get; set; }
        public Guid CustomerId { get; set; }
        public Guid StoreId { get; set; }
        public double Amount { get; set; }      // Số tiền (+ hoặc -)
        public string Action { get; set; }      // "Order", "Payment"
        public string? Reason { get; set; }     // "Thu tiền", "Mua hàng"
        public string? Note { get; set; }       // Ghi chú thêm
        
        // 👇 Dùng tên này để khớp với Controller
        public DateTime Timestamp { get; set; } = DateTime.UtcNow; 
        
        public double? NewDebtSnapshot { get; set; } // Lưu lại số nợ tại thời điểm đó
    }
}