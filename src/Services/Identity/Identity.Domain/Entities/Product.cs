namespace Identity.Domain.Entities
{
    public class Product
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public string Name { get; set; }  // Ví dụ: "Xi măng Hà Tiên"
        public decimal Price { get; set; } // Ví dụ: 80000
        public string Unit { get; set; }   // Ví dụ: "Bao", "Kg" (Quan trọng để AI hiểu)

        // Sản phẩm này thuộc cửa hàng nào?
        public Guid StoreId { get; set; }
        public Store Store { get; set; }
    }
}