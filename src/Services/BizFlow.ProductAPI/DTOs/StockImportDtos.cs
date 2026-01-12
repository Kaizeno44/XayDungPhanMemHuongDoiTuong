namespace BizFlow.ProductAPI.DTOs
{
    public class CreateStockImportRequest
    {
        public int ProductId { get; set; }
        public int UnitId { get; set; }
        public double Quantity { get; set; }
        public double CostPrice { get; set; }
        public string? SupplierName { get; set; }
        public string? Note { get; set; }
        public Guid StoreId { get; set; }
    }

    public class StockImportResponse
    {
        public int Id { get; set; }
        public string ProductName { get; set; }
        public string UnitName { get; set; }
        public double Quantity { get; set; }
        public double CostPrice { get; set; }
        public double TotalCost => Quantity * CostPrice;
        public string? SupplierName { get; set; }
        public DateTime ImportDate { get; set; }
        public string? Note { get; set; }
    }
}
