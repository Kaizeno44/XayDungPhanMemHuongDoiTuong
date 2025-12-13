using BizFlow.ProductAPI.Data;
using Microsoft.EntityFrameworkCore;
// 👇 Dòng này quan trọng: Nếu bạn để file Product.cs trong thư mục DbModels thì phải có dòng này
using BizFlow.ProductAPI.DbModels; 

var builder = WebApplication.CreateBuilder(args);

// ==========================================
// 1. CẤU HÌNH KẾT NỐI MYSQL
// ==========================================
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

// Đăng ký ProductDbContext
builder.Services.AddDbContext<ProductDbContext>(options =>
{
    // Tự động phát hiện version MySQL
    options.UseMySql(connectionString, ServerVersion.AutoDetect(connectionString));
});

// ==========================================
// 2. CÁC DỊCH VỤ CƠ BẢN (Controller, Swagger)
// ==========================================
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// ==========================================
// 3. CẤU HÌNH PIPELINE
// ==========================================
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

// ⛔️ TUYỆT ĐỐI KHÔNG CÓ DÒNG app.MapReverseProxy() Ở ĐÂY NHÉ!

app.Run();