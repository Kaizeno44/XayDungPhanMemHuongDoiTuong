using BizFlow.ProductAPI.Data;
using Microsoft.EntityFrameworkCore;
using BizFlow.ProductAPI.DbModels; 
using System.Text.Json.Serialization;
// --- THÊM CÁC THƯ VIỆN NÀY ĐỂ DÙNG JWT ---
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// ==========================================
// 1. CẤU HÌNH KẾT NỐI MYSQL
// ==========================================
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

builder.Services.AddDbContext<ProductDbContext>(options =>
{
    options.UseMySql(connectionString, ServerVersion.AutoDetect(connectionString));
});

// ==========================================
// 2. CẤU HÌNH JWT (QUAN TRỌNG - MỚI THÊM)
// ==========================================
// Đây là phần cấu hình để hệ thống hiểu và kiểm tra "thẻ bài" (Token)
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        // Lấy Key bí mật từ appsettings.json, nếu không có thì dùng key mặc định bên dưới để test
        var keyVal = builder.Configuration["Jwt:Key"] ?? "DayLaMotCaiKeyBiMatRatDaiDeTestJWT123456";
        var key = Encoding.UTF8.GetBytes(keyVal);
        
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = false, // Tạm thời bỏ qua check người phát hành
            ValidateAudience = false, // Tạm thời bỏ qua check người nhận
            ValidateLifetime = true,  // Kiểm tra xem token còn hạn không
            ValidateIssuerSigningKey = true, // Kiểm tra chữ ký có đúng key không
            IssuerSigningKey = new SymmetricSecurityKey(key)
        };
    });

// ==========================================
// 3. CÁC DỊCH VỤ CƠ BẢN
// ==========================================
builder.Services.AddControllers()
    .AddJsonOptions(x => x.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles);
    
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// ==========================================
// 4. CẤU HÌNH PIPELINE (MIDDLEWARE)
// ==========================================
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

// --- QUAN TRỌNG: UseAuthentication PHẢI ĐỨNG TRƯỚC UseAuthorization ---
app.UseAuthentication(); // <--- MỚI THÊM: Kiểm tra "Bạn là ai?"
app.UseAuthorization();  // <--- CŨ: Kiểm tra "Bạn có quyền gì?"

app.MapControllers();

// ==========================================
// 5. TỰ ĐỘNG TẠO DỮ LIỆU MẪU (SEEDING)
// ==========================================
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        var context = services.GetRequiredService<ProductDbContext>();
        
        // Kiểm tra xem bảng Categories đã có dữ liệu chưa
        if (!context.Categories.Any())
        {
            context.Categories.Add(new Category 
            { 
                Name = "Vật liệu xây dựng",
                Code = "VL_XD" 
            });
            
            context.SaveChanges();
            Console.WriteLine("--> Đã tạo dữ liệu mẫu Category thành công!");
        }
    }
    catch (Exception ex)
    {
        Console.WriteLine("--> Lỗi khi tạo dữ liệu mẫu: " + ex.Message);
    }
}

app.Run();