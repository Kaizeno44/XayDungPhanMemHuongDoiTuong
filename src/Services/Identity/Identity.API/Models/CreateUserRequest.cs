namespace Identity.API.Models
{
    public class CreateUserRequest
    {
// 👇 Thêm giá trị mặc định để hết báo lỗi vàng
        public string Email { get; set; } = string.Empty;
        
        public string Password { get; set; } = string.Empty;
        
        public string FullName { get; set; } = string.Empty;
        public string Role { get; set; } = "Employee";    
    }
}