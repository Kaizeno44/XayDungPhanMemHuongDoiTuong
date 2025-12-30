using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Identity.API.Data;

namespace Identity.API.Data
{
    public class AppDbContextFactory : IDesignTimeDbContextFactory<AppDbContext>
    {
        public AppDbContext CreateDbContext(string[] args)
        {
            var optionsBuilder = new DbContextOptionsBuilder<AppDbContext>();

            // Chuỗi kết nối đến PostgreSQL (Đã chuẩn)
            var connectionString = "Host=127.0.0.1;Port=5432;Database=bizflow_identity_db;Username=admin;Password=Password123!;";
            
            // 👇 SỬA Ở ĐÂY: Chỉ truyền connectionString, XÓA đoạn ServerVersion...
            optionsBuilder.UseNpgsql(connectionString); 

            return new AppDbContext(optionsBuilder.Options);
        }
    }
}