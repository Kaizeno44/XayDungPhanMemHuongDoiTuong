using Identity.Application.Services;
using Identity.Application.DTOs;
using Identity.Domain.Entities;
using Identity.Infrastructure.Persistence; // Cần reference tới DB Context
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace Identity.Infrastructure.Services
{
    public class AuthService : IAuthService
    {
        private readonly IdentityDbContext _context;
        private readonly IConfiguration _configuration;

        public AuthService(IdentityDbContext context, IConfiguration configuration)
        {
            _context = context;
            _configuration = configuration;
        }

        public async Task<string> RegisterAsync(RegisterRequest request)
        {
            // 1. Check xem email tồn tại chưa
            if (await _context.Users.AnyAsync(u => u.Email == request.Email))
                throw new Exception("Email đã tồn tại!");

            // 2. Lấy gói cước mặc định (Gói Basic)
            // Lưu ý: Bạn cần Insert dữ liệu gói cước vào DB trước, hoặc code logic tạo nếu chưa có
            var plan = await _context.SubscriptionPlans.FirstOrDefaultAsync(p => p.Price == 0) 
                       ?? new SubscriptionPlan { Name = "Free Trial", Price = 0, DurationInMonths = 1 };
            
            if (plan.Id == Guid.Empty) _context.SubscriptionPlans.Add(plan);

            // 3. Tạo Store mới
            var newStore = new Store
            {
                StoreName = request.StoreName,
                Address = request.StoreAddress,
                Phone = request.Phone,
                TaxCode = "",
                SubscriptionPlan = plan,
                SubscriptionExpiryDate = DateTime.UtcNow.AddMonths(plan.DurationInMonths)
            };

            // 4. Tạo User (Owner)
            var newUser = new User
            {
                FullName = request.FullName,
                Email = request.Email,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password), // Hash mật khẩu
                IsOwner = true,
                Store = newStore
            };

            _context.Users.Add(newUser);
            await _context.SaveChangesAsync();

            return "Đăng ký thành công!";
        }

        public async Task<string> LoginAsync(LoginRequest request)
        {
            // 1. Tìm User
            var user = await _context.Users
                .Include(u => u.Store) // Load kèm thông tin Store để check hạn
                .FirstOrDefaultAsync(u => u.Email == request.Email);

            if (user == null) throw new Exception("Tài khoản không tồn tại!");

            // 2. Check mật khẩu
            if (!BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
                throw new Exception("Sai mật khẩu!");

            // 3. CHECK HẠN SỬ DỤNG GÓI CƯỚC (Yêu cầu đề bài)
            if (user.Store != null && user.Store.SubscriptionExpiryDate < DateTime.UtcNow)
            {
                throw new Exception("Gói cước của bạn đã hết hạn. Vui lòng gia hạn để tiếp tục!");
            }

            // 4. Tạo Token JWT
            return GenerateJwtToken(user);
        }

        private string GenerateJwtToken(User user)
        {
            var claims = new List<Claim>
            {
                new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
                new Claim(JwtRegisteredClaimNames.Email, user.Email),
                new Claim("StoreId", user.StoreId?.ToString() ?? ""),
                new Claim("IsOwner", user.IsOwner.ToString())
            };

            // Lấy Key bí mật từ appsettings.json
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["Jwt:Key"] ?? "SecretKey_Phai_Dai_Tren_32_Ky_Tu_Nhe_Ban_Hien"));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var token = new JwtSecurityToken(
                issuer: "BizFlow",
                audience: "BizFlowUsers",
                claims: claims,
                expires: DateTime.Now.AddDays(1),
                signingCredentials: creds
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }
}