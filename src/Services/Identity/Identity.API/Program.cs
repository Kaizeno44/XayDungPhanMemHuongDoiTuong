using Identity.API.Data;
using Identity.Domain.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using Microsoft.OpenApi.Models;
using Shared.Kernel.Extensions;
using System.Reflection;
using Identity.API.Middlewares; // 👈 Thêm using này

var builder = WebApplication.CreateBuilder(args);

// 1. Cấu hình Database (PostgreSQL)
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<AppDbContext>(options =>
{
    options.UseNpgsql(connectionString);
});

// 2. Cấu hình REDIS (Cache)
builder.Services.AddStackExchangeRedisCache(options =>
{
    options.Configuration = builder.Configuration.GetConnectionString("RedisConnection");
    options.InstanceName = "BizFlow_Identity_";
});

// 3. Cấu hình IDENTITY (User/Role)
builder.Services.AddIdentity<User, Role>(options => {
    options.Password.RequireDigit = false;
    options.Password.RequiredLength = 4;
    options.Password.RequireNonAlphanumeric = false;
    options.Password.RequireUppercase = false;
    options.Password.RequireLowercase = false;
})
    .AddEntityFrameworkStores<AppDbContext>()
    .AddDefaultTokenProviders();

// 🔥 4. CẤU HÌNH JWT (THÊM ĐOẠN NÀY ĐỂ FIX LỖI 404) 🔥
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.SaveToken = true;
    options.RequireHttpsMetadata = false;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidAudience = builder.Configuration["JwtSettings:Audience"],
        ValidIssuer = builder.Configuration["JwtSettings:Issuer"],
        // 👇 Đọc SecretKey từ appsettings.json
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["JwtSettings:SecretKey"]))
    };
});

// 5. Cấu hình CORS (Cho phép Frontend gọi vào)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.WithOrigins("http://localhost:3000") // Địa chỉ Frontend NextJS
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials();
    });
});

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();

// 5. RabbitMQ
builder.Services.AddEventBus(builder.Configuration, Assembly.GetExecutingAssembly());

// 🔥 6. CẤU HÌNH SWAGGER (HIỆN NÚT Ổ KHÓA) 🔥
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "BizFlow Identity API", Version = "v1" });

    // Định nghĩa nút Authorize (Ổ khóa)
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "Nhập token vào đây: Bearer {token}",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement()
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                },
                Scheme = "oauth2",
                Name = "Bearer",
                In = ParameterLocation.Header,
            },
            new List<string>()
        }
    });
});

// Đăng ký HttpClient để gọi sang Service khác
builder.Services.AddHttpClient();

var app = builder.Build();

// --- DATA SEEDING & MIGRATION ---
Console.WriteLine("--> System: Preparing to migrate and seed database...");
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try {
        var context = services.GetRequiredService<AppDbContext>();
        
        Console.WriteLine("--> System: Running Migrations...");
        await context.Database.MigrateAsync(); 
        Console.WriteLine("--> System: Migrations completed.");

        // --- TỰ ĐỘNG TẠO BẢNG FEEDBACKS (VÌ THIẾU MIGRATION) ---
        try {
            var createTableSql = @"
                CREATE TABLE IF NOT EXISTS ""Feedbacks"" (
                    ""Id"" UUID PRIMARY KEY,
                    ""Title"" TEXT NOT NULL,
                    ""Content"" TEXT NOT NULL,
                    ""CreatedAt"" TIMESTAMP WITH TIME ZONE NOT NULL,
                    ""IsResolved"" BOOLEAN NOT NULL,
                    ""UserId"" UUID NOT NULL,
                    ""StoreId"" UUID NULL,
                    CONSTRAINT ""FK_Feedbacks_Users_UserId"" FOREIGN KEY (""UserId"") REFERENCES ""AspNetUsers"" (""Id"") ON DELETE CASCADE,
                    CONSTRAINT ""FK_Feedbacks_Stores_StoreId"" FOREIGN KEY (""StoreId"") REFERENCES ""Stores"" (""Id"") ON DELETE SET NULL
                );";
            await context.Database.ExecuteSqlRawAsync(createTableSql);
            Console.WriteLine("--> System: Feedbacks table checked/created.");
        } catch (Exception ex) {
            Console.WriteLine("--> System: Error creating Feedbacks table: " + ex.Message);
        }

        var userManager = services.GetRequiredService<UserManager<User>>();
        var roleManager = services.GetRequiredService<RoleManager<Role>>();
        
        Console.WriteLine("--> System: Starting Seeder...");
        await IdentityDataSeeder.SeedAsync(context, userManager, roleManager);

        // Đồng bộ StoreId cho Nguyễn Văn Ba (Sử dụng mã ID thực tế đang hoạt động)
        var baStoreId = Guid.Parse("404fb81a-d226-4408-9385-60f666e1c001");
        var baUser = await userManager.FindByEmailAsync("owner@bizflow.com");
        
        if (baUser != null && baUser.StoreId != baStoreId) {
            baUser.StoreId = baStoreId;
            await userManager.UpdateAsync(baUser);
            Console.WriteLine($"--> System: Reverted Nguyễn Văn Ba to StoreId: {baStoreId}");
        }

        Console.WriteLine("--> System: Seeding process finished.");
    } catch (Exception ex) {
        Console.WriteLine("****************************************************");
        Console.WriteLine($"--> LỖI NGHIÊM TRỌNG: {ex.Message}");
        if (ex.InnerException != null) 
            Console.WriteLine($"--> Chi tiết: {ex.InnerException.Message}");
        Console.WriteLine("****************************************************");
    }
}

// --- PIPELINE ---

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("AllowAll");

// 👇 Thứ tự quan trọng: Authentication -> Blacklist -> Authorization
app.UseAuthentication(); 
app.UseTokenBlacklist(); // 👈 Đăng ký Middleware Blacklist (Sau Auth để có User Role)
app.UseAuthorization();

app.MapControllers();

app.Run();
