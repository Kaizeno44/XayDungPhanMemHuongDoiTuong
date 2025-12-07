namespace Identity.Domain.Entities
{
    public class SubscriptionPlan
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public string Name { get; set; } // Ví dụ: "Gói Cơ Bản", "Gói Nâng Cao"
        public decimal Price { get; set; } // 100.000 VND
        public int DurationInMonths { get; set; } // 1 tháng, 12 tháng
        
        // Các giới hạn (Ví dụ: Gói Free chỉ tạo được 100 đơn/tháng)
        public int MaxEmployees { get; set; } 
        public bool AllowAI { get; set; } // Gói xịn mới được dùng AI
    }
}
