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

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.Run();