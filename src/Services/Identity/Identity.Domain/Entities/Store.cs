namespace Identity.Domain.Entities
{
    public class Store
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public string StoreName { get; set; } // "Cửa hàng vật liệu Ba Tèo"
        public string Address { get; set; }   // In lên hóa đơn
        public string Phone { get; set; }
        public string TaxCode { get; set; }   // Mã số thuế (nếu có)

        // --- Quản lý Gói cước ---
        public Guid SubscriptionPlanId { get; set; }
        public SubscriptionPlan SubscriptionPlan { get; set; }
        public DateTime SubscriptionExpiryDate { get; set; } // Ngày hết hạn

        // Danh sách nhân viên + Ông chủ
        public ICollection<User> Users { get; set; }
    }
}