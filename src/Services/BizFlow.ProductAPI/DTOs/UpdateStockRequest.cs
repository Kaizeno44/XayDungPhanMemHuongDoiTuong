namespace BizFlow.ProductAPI.DTOs
{
    public class UpdateStockRequest
    {
        public int ProductId { get; set; }
        public int UnitId { get; set; }
        
        // Số lượng thay đổi (Dương là nhập thêm, Âm là xuất đi/bán/hủy)
        public double QuantityChange { get; set; }
    }
}