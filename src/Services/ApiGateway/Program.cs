var builder = WebApplication.CreateBuilder(args);

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

app.MapReverseProxy();

app.Run();