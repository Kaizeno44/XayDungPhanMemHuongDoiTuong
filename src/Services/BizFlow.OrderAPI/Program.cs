using BizFlow.OrderAPI.Data;
using Microsoft.EntityFrameworkCore;
using BizFlow.OrderAPI.Services;
using QuestPDF.Infrastructure;
using MassTransit; // [1] Thêm thư viện MassTransit

QuestPDF.Settings.License = LicenseType.Community;

var builder = WebApplication.CreateBuilder(args);

// --- CẤU HÌNH KẾT NỐI DB ---
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<OrderDbContext>(options =>
    options.UseMySql(connectionString, new MySqlServerVersion(new Version(8, 0, 0))));
// ----------------------------

// --- [2] CẤU HÌNH RABBITMQ (MASS TRANSIT) ---
builder.Services.AddMassTransit(x =>
{
    // Cấu hình sử dụng RabbitMQ
    x.UsingRabbitMq((context, cfg) =>
    {
        // Lưu ý: Nếu chạy Docker Compose thì host thường là "rabbitmq"
        // Nếu chạy Debug Visual Studio (Local) thì là "localhost"
        cfg.Host("localhost", "/", h =>
        {
            h.Username("guest");
            h.Password("guest");
        });

        cfg.ConfigureEndpoints(context);
    });
});
// ---------------------------------------------

builder.Services.AddHttpClient<ProductServiceClient>(client =>
{
    client.BaseAddress = new Uri("http://localhost:5002");
});

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddSignalR();

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll",
        builder => builder
            .WithOrigins("http://localhost:3000") // URL của Frontend Next.js
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials());
});

var app = builder.Build();

// --- Middleware Pipeline ---
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}
app.UseCors("AllowAll");

app.MapHub<BizFlow.OrderAPI.Hubs.NotificationHub>("/hubs/notifications");

app.UseAuthorization();
app.MapControllers();

// --- DATA SEEDING (Tạo dữ liệu mẫu) ---
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        var context = services.GetRequiredService<OrderDbContext>();
        context.Database.EnsureCreated();

        // 1. Tạo Khách hàng mẫu
        if (!context.Customers.Any())
        {
            context.Customers.Add(new BizFlow.OrderAPI.DbModels.Customer
            {
                Id = Guid.Parse("c4608c0c-847e-468e-976e-5776d5483011"),
                FullName = "Nguyễn Văn A",
                PhoneNumber = "0901234567",
                Address = "123 Đường ABC, Quận 1, TP.HCM",
                CurrentDebt = 0,
                StoreId = Guid.NewGuid()
            });
            context.Customers.Add(new BizFlow.OrderAPI.DbModels.Customer
            {
                Id = Guid.Parse("d5708c0c-847e-468e-976e-5776d5483022"),
                FullName = "Trần Thị B",
                PhoneNumber = "0907654321",
                Address = "456 Đường XYZ, Quận 2, TP.HCM",
                CurrentDebt = 500000,
                StoreId = Guid.NewGuid()
            });
            context.SaveChanges();
            Console.WriteLine("--> Order Service: Đã tạo DB + dữ liệu khách hàng mẫu thành công!");
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

            context.SaveChanges();
            Console.WriteLine("--> Order Service: Đã tạo dữ liệu mẫu cho Sổ quỹ và Doanh thu!");
        }
    }
    catch (Exception ex)
    {
        Console.WriteLine("--> Lỗi khởi tạo DB Order: " + ex.Message);
    }
}

app.Run();