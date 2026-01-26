using BizFlow.OrderAPI.DbModels;
using Microsoft.EntityFrameworkCore;
using MassTransit;

namespace BizFlow.OrderAPI.Data
{
    public class OrderDbContext : DbContext
    {
        public OrderDbContext(DbContextOptions<OrderDbContext> options)
            : base(options)
        {
        }

        public DbSet<Order> Orders { get; set; }
        public DbSet<OrderItem> OrderItems { get; set; }
        public DbSet<Customer> Customers { get; set; }
        public DbSet<DebtLog> DebtLogs { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // MassTransit Outbox
            modelBuilder.AddInboxStateEntity();
            modelBuilder.AddOutboxMessageEntity();
            modelBuilder.AddOutboxStateEntity();

            // Orders - OrderItems
            modelBuilder.Entity<Order>()
                .HasMany(o => o.OrderItems)
                .WithOne(i => i.Order)
                .HasForeignKey(i => i.OrderId);

            // Orders - Customers
            modelBuilder.Entity<Order>()
                .HasOne(o => o.Customer)
                .WithMany(c => c.Orders)
                .HasForeignKey(o => o.CustomerId)
                .OnDelete(DeleteBehavior.Restrict);

            // Customers - DebtLogs
            modelBuilder.Entity<DebtLog>()
                .HasOne(d => d.Customer)
                .WithMany(c => c.DebtLogs)
                .HasForeignKey(d => d.CustomerId)
                .OnDelete(DeleteBehavior.Restrict);

            // DebtLogs - Orders (optional)
            modelBuilder.Entity<DebtLog>()
                .HasOne(d => d.Order)
                .WithMany()
                .HasForeignKey(d => d.RefOrderId)
                .OnDelete(DeleteBehavior.SetNull);
        }
    }
}
