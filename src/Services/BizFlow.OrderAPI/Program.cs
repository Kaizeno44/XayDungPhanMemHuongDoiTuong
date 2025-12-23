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

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.Run();