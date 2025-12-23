namespace BizFlow.ProductAPI.DTOs
{
    public class CreateCategoryRequest
    {
        // Thêm = string.Empty để tránh lỗi null
        public string Name { get; set; } = string.Empty;
        public string Code { get; set; } = string.Empty;
    }
}