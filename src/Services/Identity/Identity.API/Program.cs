using Identity.Application.Services;      // <-- 1. Import cái Interface
using Identity.Infrastructure.Persistence;
using Identity.Infrastructure.Services;   // <-- 2. Import cái Class AuthService (nơi mình vừa chuyển nhà cho nó)
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// --- Cấu hình DB ---
builder.Services.AddDbContext<IdentityDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

// --- Cấu hình Controller ---
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// =========================================================
// 👇👇👇 THÊM DÒNG NÀY VÀO ĐÂY (NÓ ĐANG BỊ THIẾU) 👇👇👇
builder.Services.AddScoped<IAuthService, AuthService>();
// =========================================================

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseAuthorization();
app.MapControllers();

app.Run();