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
builder.Services.AddSignalR(); // Thêm SignalR services

// Thêm CORS policy cho SignalR
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll",
        builder => builder
            .WithOrigins("http://localhost:3000", "http://10.0.2.2:5000") // Cho phép từ Flutter app và Gateway
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials()); // Bắt buộc phải có dòng này với SignalR
});

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
app.MapHub<BizFlow.ProductAPI.Hubs.ProductHub>("/hubs/products"); // Map SignalR Hub

// ==========================================
// 5. TỰ ĐỘNG TẠO DỮ LIỆU MẪU (SỬ DỤNG SEEDER)
// ==========================================
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        var context = services.GetRequiredService<ProductDbContext>();
        // Gọi Seeder để khởi tạo dữ liệu
        await BizFlow.ProductAPI.Data.ProductDataSeeder.SeedAsync(context);
        Console.WriteLine("--> Product Service: Database check & Seeding completed.");
    }
    catch (Exception ex)
    {
        Console.WriteLine("--> Lỗi khởi tạo DB Product: " + ex.Message);
    }
}

app.Run();
