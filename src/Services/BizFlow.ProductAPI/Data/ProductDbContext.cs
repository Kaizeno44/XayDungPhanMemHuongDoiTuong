using Microsoft.EntityFrameworkCore;
using BizFlow.ProductAPI.DbModels;

namespace BizFlow.ProductAPI.Data
{
    public class ProductDbContext : DbContext
    {
        public ProductDbContext(DbContextOptions<ProductDbContext> options) : base(options) { }

        public DbSet<Product> Products { get; set; }
        public DbSet<Category> Categories { get; set; }
        public DbSet<ProductUnit> ProductUnits { get; set; }
        public DbSet<Inventory> Inventories { get; set; }
        public DbSet<StockImport> StockImports { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            
            // Cấu hình relationship 1-1 giữa Product và Inventory
            modelBuilder.Entity<Product>()
                .HasOne(p => p.Inventory)
                .WithOne(i => i.Product)
                .HasForeignKey<Inventory>(i => i.ProductId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
