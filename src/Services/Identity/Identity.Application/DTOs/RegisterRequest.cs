namespace Identity.Application.DTOs
{
    public class RegisterRequest
    {
        public required string FullName { get; set; }
        public required string Email { get; set; }
        public required string Password { get; set; }
        public required string StoreName { get; set; } // Tên cửa hàng
        public required string StoreAddress { get; set; }
        public required string Phone { get; set; }
    }
}
