using BizFlow.OrderAPI.DbModels;
using Microsoft.EntityFrameworkCore;

namespace BizFlow.OrderAPI.Data
{
    public class OrderDbContext : DbContext
    {
        public OrderDbContext(DbContextOptions<OrderDbContext> options) : base(options) { }

        public DbSet<Customer> Customers { get; set; }
        public DbSet<Order> Orders { get; set; }
        public DbSet<OrderItem> OrderItems { get; set; } // Đảm bảo có dòng này
        public DbSet<DebtLog> DebtLogs { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Cấu hình quan hệ Order -> OrderItems
            modelBuilder.Entity<Order>()
                .HasMany(o => o.OrderItems)
                .WithOne(i => i.Order)
                .HasForeignKey(i => i.OrderId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}