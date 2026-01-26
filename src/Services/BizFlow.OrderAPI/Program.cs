using BizFlow.OrderAPI.Data;
using Microsoft.EntityFrameworkCore;
using BizFlow.OrderAPI.Services;
using QuestPDF.Infrastructure;
using MassTransit; 
using BizFlow.OrderAPI.Hubs;
using Shared.Kernel.Extensions;
using System.Reflection;

QuestPDF.Settings.License = LicenseType.Community;

var builder = WebApplication.CreateBuilder(args);

// =========================================================================
// 1. CẤU HÌNH DATABASE (MySQL)
// =========================================================================
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<OrderDbContext>(options =>
{
    options.UseMySql(connectionString, new MySqlServerVersion(new Version(8, 0, 0)));
});

// =========================================================================
// 2. CẤU HÌNH RABBITMQ (MASS TRANSIT + OUTBOX)
// =========================================================================
// builder.Services.AddMassTransit(x =>
// {
//     // A. Cấu hình Outbox Pattern cho EF Core
//     // Giúp đảm bảo tính toàn vẹn: Order lưu thành công -> Message mới được gửi đi.
//     x.AddEntityFrameworkOutbox<OrderDbContext>(o =>
//     {
//         // Cấu hình lock statement provider cho MySQL
//         o.UseMySql(); 
// 
//         // Message sẽ được đẩy vào bảng Outbox trong cùng Transaction với SaveChangesAsync
//         o.UseBusOutbox(); 
//     });
// 
//     // B. Cấu hình RabbitMQ Transport
//     x.UsingRabbitMq((context, cfg) =>
//     {
//         // Lấy thông tin từ appsettings.json (hoặc dùng mặc định nếu null)
//         var rabbitMqHost = builder.Configuration["RabbitMq:Host"] ?? "localhost";
//         var rabbitMqUser = builder.Configuration["RabbitMq:Username"] ?? "guest";
//         var rabbitMqPass = builder.Configuration["RabbitMq:Password"] ?? "guest";
// 
//         cfg.Host(rabbitMqHost, "/", h =>
//         {
//             h.Username(rabbitMqUser);
//             h.Password(rabbitMqPass);
//         });
// 
//         // Tự động cấu hình các endpoint
//         cfg.ConfigureEndpoints(context);
//     });
// });

// =========================================================================
// 3. CÁC SERVICE KHÁC
// =========================================================================
// HttpClient để gọi sang Product Service (Synchronous Check)
builder.Services.AddHttpClient<ProductServiceClient>(client =>
{
    // Lấy URL từ config để dễ deploy (vd: Docker)
    var productApiUrl = builder.Configuration["ServiceUrls:ProductApi"] ?? "http://localhost:5002";
    client.BaseAddress = new Uri(productApiUrl);
});

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddSignalR();

// Thêm RabbitMQ
builder.Services.AddEventBus(builder.Configuration, Assembly.GetExecutingAssembly());

// CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll",
        b => b.WithOrigins("http://localhost:3000", "http://10.0.2.2:3000") // Thêm IP Android Emulator
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials());
});

var app = builder.Build();

// =========================================================================
// 4. MIDDLEWARE PIPELINE
// =========================================================================
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("AllowAll");

// SignalR Hub Endpoint
app.MapHub<NotificationHub>("/hubs/notifications");

app.UseAuthorization();
app.MapControllers();

// =========================================================================
// 5. DATA SEEDING & MIGRATION
// =========================================================================
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        var context = services.GetRequiredService<OrderDbContext>();
        
        // Tự động Migrate DB nếu chưa có (Tạo bảng Outbox, Inbox...)
        // context.Database.Migrate(); // Khuyến khích dùng thay cho EnsureCreated
        context.Database.EnsureCreated();

        // Cập nhật StoreId cho toàn bộ dữ liệu cũ (Nguyễn Văn Ba)
        try {
            var baStoreId = "404fb81a-d226-4408-9385-60f666e1c001"; // 👈 Dùng ID thực tế đang hoạt động
            await context.Database.ExecuteSqlRawAsync($"UPDATE Orders SET StoreId = '{baStoreId}';");
            await context.Database.ExecuteSqlRawAsync($"UPDATE Customers SET StoreId = '{baStoreId}';");
            await context.Database.ExecuteSqlRawAsync($"UPDATE DebtLogs SET StoreId = '{baStoreId}';");
            Console.WriteLine("--> Order Service: Migrated all orders, customers, and debt logs to Nguyễn Văn Ba store.");
        } catch (Exception ex) {
            Console.WriteLine("--> Order Service: Migration error: " + ex.Message);
        }

        await SeedDataAsync(context);
    }
    catch (Exception ex)
    {
        Console.WriteLine("--> Lỗi khởi tạo DB Order: " + ex.Message);
    }
}

app.Run();

// =========================================================================
// 6. HELPER METHODS (Seeding Tách Riêng)
// =========================================================================
static async Task SeedDataAsync(OrderDbContext context)
{
    // 1. Tạo Khách hàng mẫu
    if (!context.Customers.Any())
    {
        context.Customers.AddRange(
            new BizFlow.OrderAPI.DbModels.Customer
            {
                Id = Guid.Parse("c4608c0c-847e-468e-976e-5776d5483011"),
                FullName = "Nguyễn Văn A",
                PhoneNumber = "0901234567",
                Address = "123 Đường ABC, Quận 1, TP.HCM",
                CurrentDebt = 0,
                StoreId = Guid.NewGuid()
            },
            new BizFlow.OrderAPI.DbModels.Customer
            {
                Id = Guid.Parse("d5708c0c-847e-468e-976e-5776d5483022"),
                FullName = "Trần Thị B",
                PhoneNumber = "0907654321",
                Address = "456 Đường XYZ, Quận 2, TP.HCM",
                CurrentDebt = 500000,
                StoreId = Guid.NewGuid()
            }
        );
        await context.SaveChangesAsync();
        Console.WriteLine("--> Order Service: Đã Seed Customers!");
    }


}
