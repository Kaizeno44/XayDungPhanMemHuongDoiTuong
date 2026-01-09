using Microsoft.AspNetCore.Mvc;
using Identity.Domain.Entities;
using Microsoft.AspNetCore.Identity; // 👈 Quan trọng: Để dùng UserManager
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace Identity.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        // 👇 Thay _context bằng _userManager (Trợ lý đắc lực của Identity)
        private readonly UserManager<User> _userManager;
        private readonly IConfiguration _configuration;

        public AuthController(UserManager<User> userManager, IConfiguration configuration)
        {
            _userManager = userManager;
            _configuration = configuration;
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            // 1. Tìm user bằng UserManager (An toàn hơn tự query)
            var user = await _userManager.FindByEmailAsync(request.Email);

            // 2. Kiểm tra Mật khẩu (Phải dùng hàm CheckPasswordAsync để so khớp Hash)
            // ❌ Code cũ sai: if (user.PasswordHash == request.Password)
            if (user == null || !await _userManager.CheckPasswordAsync(user, request.Password))
            {
                return Unauthorized("Sai tài khoản hoặc mật khẩu.");
            }

            // 3. Kiểm tra khóa tài khoản
            if (!user.IsActive)
            {
                return StatusCode(403, "Tài khoản bị khóa.");
            }

            try
            {
                // 4. Lấy Role (Identity tự lấy từ bảng AspNetUserRoles)
                var roles = await _userManager.GetRolesAsync(user);
                var roleName = roles.FirstOrDefault() ?? "Employee";

                // 5. Tạo Token (Truyền role vào để đóng dấu)
                var token = GenerateJwtToken(user, roleName);

                // 6. Trả về kết quả
                return Ok(new
                {
                    Token = token,
                    User = new
                    {
                        Id = user.Id,
                        FullName = user.FullName,
                        Role = roleName,
                        StoreId = user.StoreId,
                        IsOwner = user.IsOwner
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Lỗi hệ thống: {ex.Message}");
            }
        }

        // --- HÀM TẠO TOKEN ---
        private string GenerateJwtToken(User user, string roleName)
        {
            var jwtSettings = _configuration.GetSection("JwtSettings");
            var secretKey = jwtSettings["SecretKey"];

            if (string.IsNullOrEmpty(secretKey))
                throw new Exception("Chưa cấu hình SecretKey trong appsettings.json");

            var key = Encoding.ASCII.GetBytes(secretKey);

            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim(ClaimTypes.Email, user.Email ?? ""),
                new Claim(ClaimTypes.Name, user.FullName ?? ""),
                new Claim(ClaimTypes.Role, roleName) // Role lấy từ tham số truyền vào
            };

            // Thêm Claim IsOwner
            if (user.IsOwner)
            {
                claims.Add(new Claim("IsOwner", "True"));
            }

            // Thêm Claim StoreId
            if (user.StoreId.HasValue)
            {
                claims.Add(new Claim("StoreId", user.StoreId.Value.ToString()));
            }

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(claims),
                Expires = DateTime.UtcNow.AddMinutes(double.Parse(jwtSettings["DurationInMinutes"] ?? "60")),
                SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature),
                Issuer = jwtSettings["Issuer"],
                Audience = jwtSettings["Audience"]
            };

            var tokenHandler = new JwtSecurityTokenHandler();
            var token = tokenHandler.CreateToken(tokenDescriptor);
            return tokenHandler.WriteToken(token);
        }
    }

    public class LoginRequest
    {
        public string Email { get; set; }
        public string Password { get; set; }
    }
}