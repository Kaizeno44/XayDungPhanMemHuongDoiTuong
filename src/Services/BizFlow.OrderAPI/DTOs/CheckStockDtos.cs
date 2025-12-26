namespace BizFlow.OrderAPI.DTOs
{
    public class CheckStockRequest
    {
        public int ProductId { get; set; }
        public int UnitId { get; set; }
        public int Quantity { get; set; }
    }

    public class CheckStockResult
    {
        public int ProductId { get; set; }
        public bool IsEnough { get; set; }
        public required string Message { get; set; }
        public decimal UnitPrice { get; set; }
    }
}
