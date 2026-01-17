namespace Identity.Domain.Entities
{
    public class Customer
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public string FullName { get; set; }
        public string PhoneNumber { get; set; }
        public string? Address { get; set; } // Địa chỉ (tùy chọn)
        
        // Quản lý công nợ
        public decimal DebtBalance { get; set; } = 0; // Mặc định nợ = 0

        // Khách hàng này thuộc cửa hàng nào? (Quan trọng để không bị lộ data sang cửa hàng khác)
        public Guid StoreId { get; set; }
        public Store Store { get; set; }
    }
}