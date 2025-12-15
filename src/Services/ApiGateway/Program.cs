var builder = WebApplication.CreateBuilder(args);

// 1. Thêm dịch vụ CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.WithOrigins("http://localhost:3000") // Chỉ cho phép Web Admin vào
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials();
    });
});
// --- CẤU HÌNH YARP (ĐÃ SỬA ĐỔI) ---
builder.Services.AddReverseProxy()
    .LoadFromConfig(builder.Configuration.GetSection("ReverseProxy"))
    .ConfigureHttpClient((context, handler) =>
    {
        // 👇 DÒNG NÀY LÀ CHÌA KHÓA ĐỂ SỬA LỖI 502
        // Nó bảo hệ thống: "Gặp chứng chỉ lỗi cũng cứ coi là đúng (return true)"
        handler.SslOptions.RemoteCertificateValidationCallback = (sender, cert, chain, sslPolicyErrors) => true;
    });

var app = builder.Build();
app.UseCors("AllowAll");
app.MapReverseProxy();

app.Run();