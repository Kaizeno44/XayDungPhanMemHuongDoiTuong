using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Identity.API.Data;
using Identity.Domain.Entities;
using System.Security.Claims;
using System.Text;
using System.IdentityModel.Tokens.Jwt;
using Microsoft.IdentityModel.Tokens;

namespace Identity.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IConfiguration _configuration;

        public AuthController(AppDbContext context, IConfiguration configuration)
        {
            _context = context;
            _configuration = configuration;
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            // 1. Tìm user
            var user = await _context.Users
                .Include(u => u.UserRoles)
                    .ThenInclude(ur => ur.Role)
                .Include(u => u.Store)
                .FirstOrDefaultAsync(u => u.Email == request.Email);

            // 2. Kiểm tra User & Pass
            if (user == null || user.PasswordHash != request.Password)
            {
                return Unauthorized("Sai tài khoản hoặc mật khẩu.");
            }

            if (!user.IsActive)
            {
                return StatusCode(403, "Tài khoản bị khóa.");
            }

            // 3. TẠO TOKEN JWT
            try 
            {
                var token = GenerateJwtToken(user);
                
                // 4. Trả về kết quả
                var roleName = user.UserRoles.FirstOrDefault()?.Role?.Name ?? "User";
                
                return Ok(new 
                { 
                    token = token,
                    user = new 
                    {
                        id = user.Id,
                        fullName = user.FullName,
                        email = user.Email,
                        role = roleName,
                        storeId = user.StoreId,
                        isOwner = user.IsOwner
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Lỗi tạo Token: {ex.Message}");
            }
        }

        // --- HÀM SINH TOKEN (ĐÃ SỬA ĐỂ KHỚP APPSETTINGS) ---
        private string GenerateJwtToken(User user)
        {
            // 👇 SỬA Ở ĐÂY: Đọc đúng section "JwtSettings" trong file appsettings của bạn
            var jwtSettings = _configuration.GetSection("JwtSettings");
            
            // 👇 SỬA Ở ĐÂY: Đọc đúng key "SecretKey"
            var secretKey = jwtSettings["SecretKey"];
            
            if (string.IsNullOrEmpty(secretKey))
            {
                throw new Exception("Chưa cấu hình JwtSettings:SecretKey trong appsettings.json");
            }

            var key = Encoding.ASCII.GetBytes(secretKey);

            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim(ClaimTypes.Email, user.Email),
                new Claim(ClaimTypes.Name, user.FullName)
            };

            var roleName = user.UserRoles.FirstOrDefault()?.Role?.Name;
            if (!string.IsNullOrEmpty(roleName))
            {
                claims.Add(new Claim(ClaimTypes.Role, roleName));
            }
            if (user.IsOwner)
            {
                claims.Add(new Claim("IsOwner", "True"));
            }

            // 👇 QUAN TRỌNG: Giữ nguyên key "StoreId" (viết hoa) để khớp với Shared.Kernel cũ
            // Hoặc đổi thành "storeId" (viết thường) nếu bạn muốn chuẩn JSON. 
            // Tạm thời tôi để "StoreId" theo code Shared.Kernel bạn gửi lúc nãy.
            if (user.StoreId.HasValue)
            {
                claims.Add(new Claim("StoreId", user.StoreId.Value.ToString()));
            }

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(claims),
                Expires = DateTime.UtcNow.AddMinutes(double.Parse(jwtSettings["DurationInMinutes"] ?? "60")), // Đọc thời gian hết hạn
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