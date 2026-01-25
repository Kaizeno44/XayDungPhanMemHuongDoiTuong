namespace BizFlow.OrderAPI.DTOs
{
    public class PayDebtRequest
    {
        public Guid CustomerId { get; set; }
        public Guid StoreId { get; set; }
        public decimal Amount { get; set; } // Số tiền khách trả
        public string? Note { get; set; }
    }
}