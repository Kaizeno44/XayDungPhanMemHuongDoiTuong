using BizFlow.ProductAPI.Data;
using Microsoft.EntityFrameworkCore;
using BizFlow.ProductAPI.DbModels; 
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using MassTransit; // [1] Import MassTransit
using BizFlow.ProductAPI.Consumers; // [2] Import namespace chứa Consumer

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
// 2. CẤU HÌNH RABBITMQ (MASS TRANSIT) - [MỚI]
// ==========================================
builder.Services.AddMassTransit(x =>
{
    // Đăng ký Consumer xử lý trừ kho
    x.AddConsumer<OrderCreatedConsumer>();

    x.UsingRabbitMq((context, cfg) =>
    {
        // Cấu hình Host RabbitMQ (giống hệt bên OrderAPI)
        cfg.Host("localhost", "/", h =>
        {
            h.Username("guest");
            h.Password("guest");
        });

        // Tự động tạo Queue dựa trên tên Consumer (biz-flow-product-api-consumers-order-created)
        cfg.ConfigureEndpoints(context);
    });
});

// ==========================================
// 3. CẤU HÌNH JWT 
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
// 4. CÁC DỊCH VỤ CƠ BẢN
// ==========================================
builder.Services.AddControllers()
    .AddJsonOptions(x => x.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles);
    
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddSignalR(); 

// CORS Policy
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll",
        b => b
            .WithOrigins(
                "http://localhost:3000",      // Web Frontend
                "http://10.0.2.2:5000",       // Android Emulator gọi Gateway
                "http://10.0.2.2:5002",       // Android Emulator gọi trực tiếp (nếu có)
                "http://10.0.2.2:3000"        // Web chạy trên máy host
            ) 
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials()); 
});

var app = builder.Build();

// ==========================================
// 5. CẤU HÌNH PIPELINE
// ==========================================
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// app.UseHttpsRedirection(); // Tắt tạm nếu chạy Local/Docker gặp lỗi SSL

app.UseCors("AllowAll");

app.UseAuthentication(); 
app.UseAuthorization();  

app.MapControllers();
app.MapHub<BizFlow.ProductAPI.Hubs.ProductHub>("/hubs/products");

// ==========================================
// 6. DATABASE SEEDING
// ==========================================
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        var context = services.GetRequiredService<ProductDbContext>();
        
        // Đảm bảo DB tồn tại trước khi Seed
        context.Database.EnsureCreated();

        // Gọi Seeder
        await BizFlow.ProductAPI.Data.ProductDataSeeder.SeedAsync(context);
        Console.WriteLine("--> Product Service: Database check & Seeding completed.");
    }
    catch (Exception ex)
    {
        Console.WriteLine("--> Lỗi khởi tạo DB Product: " + ex.Message);
    }
}

app.Run();