var builder = WebApplication.CreateBuilder(args);

// 1. Thêm dịch vụ CORS (SỬA LẠI: Chỉ dùng AllowAnyOrigin cho đơn giản)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()   // 👈 Cho phép tất cả (Xóa dòng WithOrigins đi)
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// --- CẤU HÌNH YARP ---
builder.Services.AddReverseProxy()
    .LoadFromConfig(builder.Configuration.GetSection("ReverseProxy"))
    .ConfigureHttpClient((context, handler) =>
    {
        // Bỏ qua lỗi SSL (Chỉ dùng cho Dev)
        handler.SslOptions.RemoteCertificateValidationCallback = (sender, cert, chain, sslPolicyErrors) => true;
    });

var app = builder.Build();

// app.UseHttpsRedirection(); // 👈 Đảm bảo dòng này ĐÃ BỊ COMMENT hoặc XÓA

app.UseCors("AllowAll");
app.MapReverseProxy();

app.Run();