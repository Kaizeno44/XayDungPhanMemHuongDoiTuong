namespace Identity.Application.DTOs
{
    public class RegisterRequest
    {
        public string FullName { get; set; }
        public string Email { get; set; }
        public string Password { get; set; }
        public string StoreName { get; set; } // Tên cửa hàng
        public string StoreAddress { get; set; }
        public string Phone { get; set; }
    }
}