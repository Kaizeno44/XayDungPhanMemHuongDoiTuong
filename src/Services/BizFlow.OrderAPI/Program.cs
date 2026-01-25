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

    // 2. Tạo Lịch sử Nợ & Đơn hàng mẫu
    if (!context.DebtLogs.Any())
    {
        var customerId = Guid.Parse("c4608c0c-847e-468e-976e-5776d5483011");
        var storeId = Guid.NewGuid();

        context.DebtLogs.AddRange(
            new BizFlow.OrderAPI.DbModels.DebtLog { Id = Guid.NewGuid(), CustomerId = customerId, StoreId = storeId, Amount = 1500000, Action = "Debit", Reason = "Bán hàng - Đơn ORD001", CreatedAt = DateTime.UtcNow.AddDays(-2) },
            new BizFlow.OrderAPI.DbModels.DebtLog { Id = Guid.NewGuid(), CustomerId = customerId, StoreId = storeId, Amount = -500000, Action = "Repayment", Reason = "Khách trả tiền mặt", CreatedAt = DateTime.UtcNow.AddDays(-1) },
            new BizFlow.OrderAPI.DbModels.DebtLog { Id = Guid.NewGuid(), CustomerId = customerId, StoreId = storeId, Amount = 2000000, Action = "Debit", Reason = "Bán hàng - Đơn ORD002", CreatedAt = DateTime.UtcNow }
        );

        context.Orders.AddRange(
            new BizFlow.OrderAPI.DbModels.Order { Id = Guid.NewGuid(), OrderCode = "ORD001", CustomerId = customerId, StoreId = storeId, TotalAmount = 1500000, Status = "Confirmed", PaymentMethod = "Debt", OrderDate = DateTime.UtcNow.AddDays(-2) },
            new BizFlow.OrderAPI.DbModels.Order { Id = Guid.NewGuid(), OrderCode = "ORD002", CustomerId = customerId, StoreId = storeId, TotalAmount = 2000000, Status = "Confirmed", PaymentMethod = "Debt", OrderDate = DateTime.UtcNow.AddDays(-1) },
            new BizFlow.OrderAPI.DbModels.Order { Id = Guid.NewGuid(), OrderCode = "ORD003", CustomerId = customerId, StoreId = storeId, TotalAmount = 3500000, Status = "Confirmed", PaymentMethod = "Cash", OrderDate = DateTime.UtcNow }
        );

        await context.SaveChangesAsync();
        Console.WriteLine("--> Order Service: Đã Seed Orders & Debts!");
    }
}
