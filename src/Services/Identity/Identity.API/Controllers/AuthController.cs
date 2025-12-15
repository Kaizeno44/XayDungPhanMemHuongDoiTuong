using Microsoft.AspNetCore.Mvc;
using Identity.API.Data;   // Để dùng AppDbContext
using Identity.API.Models; // Để dùng User
using System.Linq;

namespace Identity.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly AppDbContext _context;

        // Inject Database vào Controller
        public AuthController(AppDbContext context)
        {
            _context = context;
        }

        [HttpPost("login")]
        public IActionResult Login([FromBody] LoginRequest request)
        {
            // 1. Tìm user trong Database khớp Email và Password
            // (Lưu ý: Password đang lưu text thường, thực tế sẽ cần Hash)
            var user = _context.Users.FirstOrDefault(u => 
                u.Email == request.Email && 
                u.Password == request.Password
            );

            // 2. Kiểm tra kết quả
            if (user != null)
            {
                // Trả về Token kèm thông tin thật
                return Ok(new 
                { 
                    token = "fake-jwt-token-cho-admin-123456",
                    fullName = user.FullName,
                    role = user.Role
                });
            }

            return Unauthorized("Tài khoản hoặc mật khẩu không đúng!");
        }
    }

    public class LoginRequest
    {
        public string Email { get; set; }
        public string Password { get; set; }
    }
}