namespace BizFlow.ProductAPI.DTOs
{
    public class UpdateStockRequest
    {
        public int ProductId { get; set; }
        public int UnitId { get; set; }
        public double QuantityChange { get; set; }

        // Thêm = string.Empty
        public string Reason { get; set; } = string.Empty;
    }
}