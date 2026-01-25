namespace Identity.API.Models // <--- Chung namespace với file kia cho tiện
{
    public class CreateOwnerRequest
    {
        public string FullName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;

        // 👇 Cái này QUAN TRỌNG NHẤT: Phải có để tạo Cửa hàng
        public string StoreName { get; set; } = string.Empty;
        public Guid SubscriptionPlanId { get; set; } 
    }
}