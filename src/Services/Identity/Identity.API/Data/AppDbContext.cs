using Microsoft.AspNetCore.Identity; // 👈 Cần cái này cho các class Generic
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using Identity.Domain.Entities;

namespace Identity.API.Data
{
    // 👇 SỬA QUAN TRỌNG: Khai báo đầy đủ để Identity biết "UserRole" là con đẻ
    public class AppDbContext : IdentityDbContext<
        User, 
        Role, 
        Guid, 
        IdentityUserClaim<Guid>, 
        UserRole,  // 👈 Đây! Phải chỉ đích danh class này
        IdentityUserLogin<Guid>, 
        IdentityRoleClaim<Guid>, 
        IdentityUserToken<Guid>>
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
        {
        }

        public DbSet<UserDevice> UserDevices { get; set; }
        public DbSet<Store> Stores { get; set; }
        public DbSet<SubscriptionPlan> SubscriptionPlans { get; set; }
        public DbSet<Customer> Customers { get; set; }
        public DbSet<Product> Products { get; set; }
        public DbSet<Order> Orders { get; set; }
        public DbSet<OrderDetail> OrderDetails { get; set; }
        protected override void OnModelCreating(ModelBuilder builder)
        {
            base.OnModelCreating(builder);

  // --- FIX CẢNH BÁO RoleId1, UserId1 ---
            // Chỉ định rõ mối quan hệ để EF không tạo cột trùng
            builder.Entity<User>()
                .HasMany(u => u.UserRoles)
                .WithOne(ur => ur.User)
                .HasForeignKey(ur => ur.UserId)
                .IsRequired();

            builder.Entity<Role>()
                .HasMany(r => r.UserRoles)
                .WithOne(ur => ur.Role)
                .HasForeignKey(ur => ur.RoleId)
                .IsRequired();

            // --- CÁC CẤU HÌNH KHÁC CỦA BẠN (Giữ nguyên) ---
            builder.Entity<Store>()
                .HasOne(s => s.SubscriptionPlan)
                .WithMany()
                .HasForeignKey(s => s.SubscriptionPlanId);

            builder.Entity<User>()
                .HasOne(u => u.Store)
                .WithMany(s => s.Users)
                .HasForeignKey(u => u.StoreId)
                .OnDelete(DeleteBehavior.SetNull);

            // Seed Data SubscriptionPlan (Giữ nguyên như bạn làm là đúng)
            var basicPlanId = Guid.Parse("d5093c85-64e6-42c2-8098-902341270123");
            var proPlanId = Guid.Parse("60350d5e-d225-4676-9051-512686851234");

            builder.Entity<SubscriptionPlan>().HasData(
                new SubscriptionPlan
                {
                    Id = basicPlanId,
                    Name = "Gói Cơ Bản (Start-up)",
                    Price = 100000,
                    DurationInMonths = 1,
                    MaxEmployees = 2,
                    AllowAI = false
                },
                new SubscriptionPlan
                {
                    Id = proPlanId,
                    Name = "Gói Doanh Nghiệp (Pro)",
                    Price = 200000,
                    DurationInMonths = 1,
                    MaxEmployees = 10,
                    AllowAI = true
                }
            );
        }
    }
}