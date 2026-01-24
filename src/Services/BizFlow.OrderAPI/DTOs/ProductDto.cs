namespace BizFlow.OrderAPI.DTOs
{
    public class ProductDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public List<ProductUnitDto>? ProductUnits { get; set; }
    }

    public class ProductUnitDto
    {
        public int Id { get; set; }
        public string UnitName { get; set; } = string.Empty;
    }
}
