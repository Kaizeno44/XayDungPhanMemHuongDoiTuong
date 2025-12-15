using BizFlow.OrderAPI.DbModels;
using Microsoft.EntityFrameworkCore;

namespace BizFlow.OrderAPI.Data
{
    public class OrderDbContext : DbContext
    {
        public OrderDbContext(DbContextOptions<OrderDbContext> options) : base(options) { }

        public DbSet<Customer> Customers { get; set; }
        public DbSet<Order> Orders { get; set; }
        public DbSet<OrderItem> OrderItems { get; set; }
        public DbSet<DebtLog> DebtLogs { get; set; }
    }
}