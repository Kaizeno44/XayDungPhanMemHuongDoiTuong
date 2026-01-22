using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using Identity.Domain.Entities;

namespace Identity.API.Data
{
    // Khai báo đầy đủ để Identity nhận đúng UserRole
    public class AppDbContext : IdentityDbContext<
        User,
        Role,
        Guid,
        IdentityUserClaim<Guid>,
        UserRole,
        IdentityUserLogin<Guid>,
        IdentityRoleClaim<Guid>,
        IdentityUserToken<Guid>>
    {
        public AppDbContext(DbContextOptions<AppDbContext> options)
            : base(options)
        {
        }

        public DbSet<UserDevice> UserDevices { get; set; }
        public DbSet<Store> Stores { get; set; }
        public DbSet<SubscriptionPlan> SubscriptionPlans { get; set; }
        public DbSet<Customer> Customers { get; set; }
        public DbSet<Ledger> Ledgers { get; set; }

        protected override void OnModelCreating(ModelBuilder builder)
        {
            base.OnModelCreating(builder);

            // --- FIX RoleId1, UserId1 ---
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

            // --- CẤU HÌNH DOMAIN ---
            builder.Entity<Store>()
                .HasOne(s => s.SubscriptionPlan)
                .WithMany()
                .HasForeignKey(s => s.SubscriptionPlanId);

            builder.Entity<User>()
                .HasOne(u => u.Store)
                .WithMany(s => s.Users)
                .HasForeignKey(u => u.StoreId)
                .OnDelete(DeleteBehavior.SetNull);

            builder.Entity<Ledger>()
                .HasOne(l => l.Store)
                .WithMany()
                .HasForeignKey(l => l.StoreId);

            builder.Entity<Ledger>()
                .HasOne(l => l.Creator)
                .WithMany()
                .HasForeignKey(l => l.CreatedBy)
                .OnDelete(DeleteBehavior.SetNull);

            // --- SEED DATA SubscriptionPlan ---
            var basicPlanId = Guid.Parse("d5093c85-64e6-42c2-8098-902341270123");
            var proPlanId   = Guid.Parse("60350d5e-d225-4676-9051-512686851234");

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
