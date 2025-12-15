using BizFlow.ProductAPI.Data;
using Microsoft.EntityFrameworkCore;
// 👇 Dòng này quan trọng: Nếu bạn để file Product.cs trong thư mục DbModels thì phải có dòng này
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

// ⛔️ TUYỆT ĐỐI KHÔNG CÓ DÒNG app.MapReverseProxy() Ở ĐÂY NHÉ!

app.UseAuthorization();
app.MapControllers();
// Tự động tạo dữ liệu mẫu (Seeding Data)
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        var context = services.GetRequiredService<ProductDbContext>();
        
        // Kiểm tra xem bảng Categories đã có dữ liệu chưa
        if (!context.Categories.Any())
        {
            // Nếu chưa có, tạo mới một cái (Nó sẽ tự nhận ID = 1)
            context.Categories.Add(new BizFlow.ProductAPI.DbModels.Category 
            { 
                Name = "Vật liệu xây dựng",
                Description = "Các loại vật liệu cơ bản"
            });
            context.SaveChanges(); // Lưu vào DB
        }
    }
    catch (Exception ex)
    {
        Console.WriteLine("Lỗi khi tạo dữ liệu mẫu: " + ex.Message);
    }
}
app.Run();