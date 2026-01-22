using System;

namespace Identity.Domain.Entities
{
    public class Ledger
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        
        public Guid StoreId { get; set; }
        public Store Store { get; set; }

        public DateTime TransactionDate { get; set; } = DateTime.UtcNow;
        
        public string Description { get; set; } // "Thu tiền đơn hàng #123", "Chi tiền nhập hàng"
        
        public decimal Amount { get; set; } // Số tiền
        
        public string TransactionType { get; set; } // "INCOME" (Thu), "EXPENSE" (Chi)
        
        public string? ReferenceId { get; set; } // Mã đơn hàng hoặc mã phiếu nhập liên quan
        
        public Guid? CreatedBy { get; set; }
        public User? Creator { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
