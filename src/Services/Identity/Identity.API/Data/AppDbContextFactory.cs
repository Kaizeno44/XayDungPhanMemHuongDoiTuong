using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Identity.API.Data;

namespace Identity.API.Data
{
    public class AppDbContextFactory : IDesignTimeDbContextFactory<AppDbContext>
    {
        public AppDbContext CreateDbContext(string[] args)
        {
            // 1. Tạo bộ cấu hình
            var optionsBuilder = new DbContextOptionsBuilder<AppDbContext>();

            // 2. Điền chuỗi kết nối trực tiếp vào đây (Hardcode để chạy lệnh cho mượt)
            var connectionString = "Server=localhost;Port=3306;Database=BizFlow_Identity;User=root;Password=123456;";
            
            optionsBuilder.UseMySql(connectionString, ServerVersion.AutoDetect(connectionString));

            // 3. Trả về AppDbContext đã được cấu hình
            return new AppDbContext(optionsBuilder.Options);
        }
    }
}