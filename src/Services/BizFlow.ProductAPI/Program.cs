using BizFlow.ProductAPI.Data;
using Microsoft.EntityFrameworkCore;
using BizFlow.ProductAPI.DbModels; 
using System.Text.Json.Serialization;
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
    // Lưu ý: Đảm bảo chuỗi kết nối trong appsettings.json là chính xác
    options.UseMySql(connectionString, ServerVersion.AutoDetect(connectionString));
});

// ==========================================
// 2. CẤU HÌNH JWT 
// ==========================================
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        var keyVal = builder.Configuration["Jwt:Key"] ?? "DayLaMotCaiKeyBiMatRatDaiDeTestJWT123456";
        var key = Encoding.UTF8.GetBytes(keyVal);
        
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = false,
            ValidateAudience = false,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
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
// 4. CẤU HÌNH PIPELINE
// ==========================================
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthentication(); 
app.UseAuthorization();  

app.MapControllers();

// ==========================================
// 5. TỰ ĐỘNG TẠO DỮ LIỆU MẪU (ĐÃ SỬA)
// ==========================================
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        var context = services.GetRequiredService<ProductDbContext>();
        
        // 🔥🔥🔥 DÒNG QUAN TRỌNG NHẤT VỪA ĐƯỢC THÊM VÀO ĐÂY 🔥🔥🔥
        // Lệnh này kiểm tra xem DB có chưa. Chưa có thì tạo mới + tạo bảng luôn.
        context.Database.EnsureCreated(); 
        // 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥

        // Sau khi đảm bảo DB đã có, mới được phép truy vấn
        if (!context.Categories.Any())
        {
            context.Categories.Add(new Category 
            { 
                Name = "Vật liệu xây dựng",
                Code = "VL_XD" 
            });
            
            context.SaveChanges();
            Console.WriteLine("--> Product Service: Đã tạo DB + dữ liệu mẫu thành công!");
        }
    }
    catch (Exception ex)
    {
        Console.WriteLine("--> Lỗi khởi tạo DB Product: " + ex.Message);
    }
}

app.Run();
