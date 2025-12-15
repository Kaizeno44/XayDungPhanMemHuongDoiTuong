using Identity.API.Data;
using Microsoft.EntityFrameworkCore;
// using Identity.Application.Services; // (Mở lại nếu bạn đã có file này)
// using Identity.Infrastructure.Services; // (Mở lại nếu bạn đã có file này)

var builder = WebApplication.CreateBuilder(args);

// ==================================================================
// 👇 KHU VỰC 1: ĐĂNG KÝ DỊCH VỤ (NGUYÊN LIỆU) - LÀM TRƯỚC KHI BUILD
// ==================================================================

// 1. Cấu hình MySQL (Thay thế đoạn Postgres cũ)
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<AppDbContext>(options =>
{
    options.UseMySql(connectionString, ServerVersion.AutoDetect(connectionString));
});

// 2. Cấu hình CORS (Cho phép Frontend gọi vào)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// 3. Cấu hình Controller & JSON
builder.Services.AddControllers().AddJsonOptions(options =>
{
    options.JsonSerializerOptions.PropertyNameCaseInsensitive = true;
});

// 4. Swagger (Tài liệu API)
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// 5. Đăng ký Service riêng của bạn (Nếu chưa tạo file thì comment lại dòng này để tránh lỗi)
// builder.Services.AddScoped<IAuthService, AuthService>(); 

// ==================================================================
// 👇 KHU VỰC 2: BUILD APP (DÒNG RANH GIỚI QUAN TRỌNG)
// ==================================================================
var app = builder.Build(); 
// ⛔️ KHÔNG ĐƯỢC THÊM builder.Services... Ở DƯỚI DÒNG NÀY

// ==================================================================
// 👇 KHU VỰC 3: PIPELINE (SAU KHI NẤU XONG)
// ==================================================================

// 1. Swagger UI (Chỉ hiện khi Dev)
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

// 2. Kích hoạt CORS (Phải đặt trước Authorization)
app.UseCors("AllowAll");

app.UseAuthorization();

app.MapControllers();

app.Run();