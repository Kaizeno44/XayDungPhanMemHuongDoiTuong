using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using BizFlow.ProductAPI.Data; // Để tìm thấy ProductDbContext

namespace BizFlow.ProductAPI.Data
{
    public class ProductDbContextFactory : IDesignTimeDbContextFactory<ProductDbContext>
    {
        public ProductDbContext CreateDbContext(string[] args)
        {
            var optionsBuilder = new DbContextOptionsBuilder<ProductDbContext>();
            
            // Database riêng cho Product: BizFlow_Product
            var connectionString = "Server=localhost;Port=3306;Database=BizFlow_Product;User=root;Password=123456;";            
            optionsBuilder.UseMySql(connectionString, ServerVersion.AutoDetect(connectionString));

            return new ProductDbContext(optionsBuilder.Options);
        }
    }
}