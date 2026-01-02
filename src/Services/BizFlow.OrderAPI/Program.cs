using BizFlow.OrderAPI.Data;
using Microsoft.EntityFrameworkCore;
using BizFlow.OrderAPI.Services; // <--- 1. BẮT BUỘC PHẢI CÓ DÒNG NÀY

var builder = WebApplication.CreateBuilder(args);

// --- CẤU HÌNH KẾT NỐI DB ---
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<OrderDbContext>(options =>
    options.UseMySql(connectionString, new MySqlServerVersion(new Version(8, 0, 0))));
// ----------------------------

// Đăng ký ProductServiceClient để gọi sang Service B
// <--- 2. QUAN TRỌNG: THÊM DÒNG NÀY ĐỂ KẾT NỐI API KHÁC
builder.Services.AddHttpClient<ProductServiceClient>(client =>
{
    client.BaseAddress = new Uri("http://localhost:5002"); // PORT ProductAPI
});

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddSignalR();

// --- THÊM ĐOẠN NÀY ---
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll",
        builder => builder
            .WithOrigins("http://localhost:3000") // 🔥 QUAN TRỌNG: Chấp nhận mọi nguồn (HTML file, localhost...)
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials()); // Bắt buộc phải có dòng này với SignalR
});

;
var app = builder.Build();
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}
app.UseCors("AllowAll"); // <--- 3. Thêm dòng này để kích hoạt CORS

app.MapHub<BizFlow.OrderAPI.Hubs.NotificationHub>("/hubs/notifications");

// app.UseHttpsRedirection(); // Đã comment để đảm bảo API phục vụ qua HTTP
app.UseAuthorization();
app.MapControllers();

// ==========================================
// 4. TỰ ĐỘNG TẠO DỮ LIỆU MẪU CHO KHÁCH HÀNG (ĐÃ THÊM)
// ==========================================
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        var context = services.GetRequiredService<OrderDbContext>();
        context.Database.EnsureCreated(); // Đảm bảo DB và bảng được tạo

        if (!context.Customers.Any())
        {
            context.Customers.Add(new BizFlow.OrderAPI.DbModels.Customer
            {
                Id = Guid.Parse("c4608c0c-847e-468e-976e-5776d5483011"),
                FullName = "Nguyễn Văn A",
                PhoneNumber = "0901234567",
                Address = "123 Đường ABC, Quận 1, TP.HCM",
                CurrentDebt = 0,
                StoreId = Guid.NewGuid() // Tạo StoreId ngẫu nhiên
            });
            context.Customers.Add(new BizFlow.OrderAPI.DbModels.Customer
            {
                Id = Guid.Parse("d5708c0c-847e-468e-976e-5776d5483022"),
                FullName = "Trần Thị B",
                PhoneNumber = "0907654321",
                Address = "456 Đường XYZ, Quận 2, TP.HCM",
                CurrentDebt = 500000, // Có nợ ban đầu
                StoreId = Guid.NewGuid()
            });
            context.SaveChanges();
            Console.WriteLine("--> Order Service: Đã tạo DB + dữ liệu khách hàng mẫu thành công!");
        }
    }
    catch (Exception ex)
    {
        Console.WriteLine("--> Lỗi khởi tạo DB Order: " + ex.Message);
    }
}

app.Run();
