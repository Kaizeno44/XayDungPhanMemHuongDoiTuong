namespace Identity.API.Models
{
    public class CreateUserRequest
    {
        public string Email { get; set; }
        public string Password { get; set; }
        public string FullName { get; set; }
        public string Role { get; set; } // Ví dụ: "Manager" hoặc "Staff"
    }
}