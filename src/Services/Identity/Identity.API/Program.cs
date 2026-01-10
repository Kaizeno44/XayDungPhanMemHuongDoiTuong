using Identity.API.Data;
using Microsoft.EntityFrameworkCore;
using Shared.Kernel.Extensions;
using System.Reflection;

var builder = WebApplication.CreateBuilder(args);

// 1. Cấu hình PostgreSQL
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<AppDbContext>(options =>
{
    options.UseNpgsql(connectionString);
});

// 2. Cấu hình CORS
// 2. Cấu hình CORS (SỬA LẠI ĐOẠN NÀY)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.WithOrigins("http://localhost:3000") // 👈 CHỈ ĐỊNH RÕ FRONTEND CỦA BẠN
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials(); // 👈 BẮT BUỘC PHẢI CÓ ĐỂ GỬI COOKIE/TOKEN
    });
});

// 3. Cấu hình Controller
builder.Services.AddControllers().AddJsonOptions(options =>
{
    options.JsonSerializerOptions.PropertyNameCaseInsensitive = true;
});

// 4. Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// 5. RabbitMQ
builder.Services.AddEventBus(builder.Configuration, Assembly.GetExecutingAssembly());

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    // Tự động update database nếu chưa update
    await context.Database.MigrateAsync(); 
    // Chạy hàm seed
    await IdentityDataSeeder.SeedAsync(context);
}

// --- PIPELINE ---

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// ❌❌❌ QUAN TRỌNG NHẤT: COMMENT DÒNG NÀY LẠI ❌❌❌
// app.UseHttpsRedirection(); // <--- THỦ PHẠM GÂY LỖI EMPTY RESPONSE LÀ ĐÂY

app.UseCors("AllowAll");

app.UseAuthorization();

app.MapControllers();

app.Run();
