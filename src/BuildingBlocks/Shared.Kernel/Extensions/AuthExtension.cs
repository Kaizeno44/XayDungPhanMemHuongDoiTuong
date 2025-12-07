using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.Tokens;
using System.Text;

namespace Shared.Kernel.Extensions
{
    public static class AuthExtension
    {
        // Dùng IConfiguration để lấy Key trực tiếp từ file cấu hình
        public static void AddCustomJwtAuthentication(this IServiceCollection services, IConfiguration configuration)
        {
            var secretKey = configuration["Jwt:Key"];
            
            // Kiểm tra kỹ: Nếu quên cấu hình Key thì báo lỗi ngay để biết đường sửa
            if (string.IsNullOrEmpty(secretKey))
            {
                throw new Exception("Chưa cấu hình 'Jwt:Key' trong file appsettings.json!");
            }

            var keyBytes = Encoding.UTF8.GetBytes(secretKey);

            services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
                .AddJwtBearer(options =>
                {
                    options.TokenValidationParameters = new TokenValidationParameters
                    {
                        // 1. Kiểm tra chữ ký (Quan trọng nhất): Token phải do Identity ký mới chịu
                        ValidateIssuerSigningKey = true,
                        IssuerSigningKey = new SymmetricSecurityKey(keyBytes),

                        // 2. Tạm tắt kiểm tra Issuer/Audience để tránh lỗi khi chạy Docker/Localhost
                        ValidateIssuer = false, 
                        ValidateAudience = false,

                        // 3. Kiểm tra thời hạn: Token hết hạn là chặn ngay
                        ValidateLifetime = true,
                        ClockSkew = TimeSpan.Zero // Không cho phép trễ giây nào (mặc định là 5 phút)
                    };
                });
        }
    }
}