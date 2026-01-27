using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore; // 👈 Thêm using này
using Identity.Domain.Entities;
using Identity.API.Data; // 👈 Thêm using này
using Microsoft.AspNetCore.Identity; // 👈 Quan trọng: Để dùng UserManager
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.Extensions.Caching.Distributed; // 👈 Thêm using cho Redis

namespace Identity.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly AppDbContext _context; // 👈 Thêm lại context
        private readonly UserManager<User> _userManager;
        private readonly IConfiguration _configuration;
        private readonly IDistributedCache _cache; // 👈 Inject Redis Cache

        public AuthController(AppDbContext context, UserManager<User> userManager, IConfiguration configuration, IDistributedCache cache)
        {
            _context = context;
            _userManager = userManager;
            _configuration = configuration;
            _cache = cache;
        }

        [HttpPost("logout")]
        public async Task<IActionResult> Logout()
        {
            // 1. Lấy Token từ Header
            var token = Request.Headers["Authorization"].ToString().Replace("Bearer ", "");
            if (string.IsNullOrEmpty(token)) return BadRequest("Token không hợp lệ");

            // 2. Lưu Token vào Redis Blacklist
            // Thiết lập thời gian hết hạn trong Redis bằng thời gian hết hạn của Token (ở đây ta dùng 1 phút cho test)
            var options = new DistributedCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(1)
            };

            await _cache.SetStringAsync($"blacklist_{token}", "revoked", options);

            return Ok(new { message = "Đăng xuất thành công, Token đã bị vô hiệu hóa." });
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            // 0. Kiểm tra chế độ bảo trì
            var maintenance = await _cache.GetStringAsync("system_maintenance");
            bool isMaintenance = maintenance == "true";

            // 1. Tìm user
            var user = await _context.Users
                .Include(u => u.Store)
                    .ThenInclude(s => s.SubscriptionPlan)
                .FirstOrDefaultAsync(u => u.Email == request.Email);
            if (user == null)
            {
                return Unauthorized("Email này không tồn tại trong hệ thống.");
            }

            // 2. Kiểm tra Mật khẩu
            // Thêm kiểm tra sơ bộ cho dữ liệu Seed (nếu chưa hash) hoặc dùng Identity check
            bool isPasswordValid = false;
            if (user.PasswordHash == request.Password) // Hỗ trợ cho dữ liệu Seed đơn giản
            {
                isPasswordValid = true;
            }
            else
            {
                isPasswordValid = await _userManager.CheckPasswordAsync(user, request.Password);
            }

            if (!isPasswordValid)
            {
                return Unauthorized("Mật khẩu không chính xác.");
            }

            // 2.1 Lấy Role để check bảo trì
            var roles = await _userManager.GetRolesAsync(user);
            var roleName = roles.FirstOrDefault() ?? "Employee";

            // 2.2 Nếu đang bảo trì, chỉ cho phép SuperAdmin
            if (isMaintenance && roleName != "SuperAdmin")
            {
                return StatusCode(503, new { message = "Hệ thống đang bảo trì để nâng cấp. Vui lòng quay lại sau!" });
            }

            // 3. Kiểm tra khóa tài khoản
            if (!user.IsActive)
            {
                return StatusCode(403, new { message = "Tài khoản của bạn đã bị khóa. Vui lòng liên hệ Admin để mở khóa." });
            }

            try
            {
                // 4. Role đã lấy ở trên
                // 5. Lấy quyền AI từ gói cước
                bool allowAI = user.Store?.SubscriptionPlan?.AllowAI ?? false;

                // 6. Tạo Token (Truyền role vào để đóng dấu)
                var token = GenerateJwtToken(user, roleName, allowAI);

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
                        IsOwner = user.IsOwner,
                        AllowAI = allowAI.ToString() // 👈 Thêm quyền AI vào đây
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Lỗi hệ thống: {ex.Message}");
            }
        }

        // --- HÀM TẠO TOKEN ---
        private string GenerateJwtToken(User user, string roleName, bool allowAI)
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

            // Thêm quyền AI
            claims.Add(new Claim("AllowAI", allowAI.ToString()));

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
