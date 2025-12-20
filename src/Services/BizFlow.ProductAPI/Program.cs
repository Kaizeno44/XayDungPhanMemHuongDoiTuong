using BizFlow.ProductAPI.Data;
using Microsoft.EntityFrameworkCore;
using BizFlow.ProductAPI.DbModels; 
using System.Text.Json.Serialization;

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
builder.Services.AddControllers()
    .AddJsonOptions(x => x.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles);
    
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

// ==========================================
// 4. TỰ ĐỘNG TẠO DỮ LIỆU MẪU (SEEDING)
// ==========================================
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        var context = services.GetRequiredService<ProductDbContext>();
        
        // (Tùy chọn) Tự động chạy Migration nếu chưa chạy
        // context.Database.Migrate(); 

        // Kiểm tra xem bảng Categories đã có dữ liệu chưa
        if (!context.Categories.Any())
        {
            // SỬA LỖI Ở ĐÂY: Xóa Description, Thêm Code
            context.Categories.Add(new Category 
            { 
                Name = "Vật liệu xây dựng",
                Code = "VL_XD" // <--- Bắt buộc phải có Code
                // Description = "..." <--- Đã xóa dòng này đi vì Model không còn nữa
            });
            
            context.SaveChanges(); // Lưu vào DB
            Console.WriteLine("--> Đã tạo dữ liệu mẫu Category thành công!");
        }
    }
    catch (Exception ex)
    {
        Console.WriteLine("--> Lỗi khi tạo dữ liệu mẫu: " + ex.Message);
    }
}

app.Run();