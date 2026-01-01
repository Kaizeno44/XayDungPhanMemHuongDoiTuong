using Microsoft.EntityFrameworkCore;
using Identity.Domain.Entities;

namespace Identity.API.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
        {
        }

        public DbSet<User> Users { get; set; }
        public DbSet<Role> Roles { get; set; }
        public DbSet<UserRole> UserRoles { get; set; }

        public DbSet<UserDevice> UserDevices { get; set; }
        public DbSet<Store> Stores { get; set; }
        public DbSet<SubscriptionPlan> SubscriptionPlans { get; set; }

        protected override void OnModelCreating(ModelBuilder builder)
        {
            base.OnModelCreating(builder);

            // 1. Cấu hình Many-to-Many cho UserRole
            builder.Entity<UserRole>().HasKey(ur => new { ur.UserId, ur.RoleId });

            builder.Entity<UserRole>()
                .HasOne(ur => ur.User)
                .WithMany(u => u.UserRoles)
                .HasForeignKey(ur => ur.UserId);

            builder.Entity<UserRole>()
                .HasOne(ur => ur.Role)
                .WithMany(r => r.UserRoles)
                .HasForeignKey(ur => ur.RoleId);

            // 2. Cấu hình Store -> Plan
            builder.Entity<Store>()
                .HasOne(s => s.SubscriptionPlan)
                .WithMany()
                .HasForeignKey(s => s.SubscriptionPlanId);

            // 3. Cấu hình User -> Store
            builder.Entity<User>()
                .HasOne(u => u.Store)
                .WithMany(s => s.Users)
                .HasForeignKey(u => u.StoreId)
                .OnDelete(DeleteBehavior.SetNull);

            // --------------------------------------------------------
            // DATA SEEDING (Dữ liệu mẫu chuẩn GUID)
            // --------------------------------------------------------

            // ID Cố định (Dùng Guid chuẩn để tránh lỗi parse)
            var basicPlanId = Guid.Parse("d5093c85-64e6-42c2-8098-902341270123");
            var proPlanId = Guid.Parse("60350d5e-d225-4676-9051-512686851234");

            var roleSuperAdminId = Guid.Parse("18c90961-62d2-45e3-9e45-123456789001");
            var roleOwnerId = Guid.Parse("29d01072-73e3-46f4-af56-123456789002");
            var roleEmployeeId = Guid.Parse("30e12183-84f5-4705-bf67-123456789003");

            var superAdminUserId = Guid.Parse("9f6a2336-311e-4209-906d-495941c21054");

            // A. Seed SubscriptionPlan
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

            // B. Seed Roles
            builder.Entity<Role>().HasData(
                new Role { Id = roleSuperAdminId, Name = "SuperAdmin", Description = "Quản trị viên hệ thống" },
                new Role { Id = roleOwnerId, Name = "Owner", Description = "Chủ hộ kinh doanh" },
                new Role { Id = roleEmployeeId, Name = "Employee", Description = "Nhân viên bán hàng" }
            );

            // C. Seed User SuperAdmin
            builder.Entity<User>().HasData(new User
            {
                Id = superAdminUserId,
                FullName = "Quản Trị Viên Hệ Thống",
                Email = "superadmin@bizflow.com",
                PasswordHash = "admin", // Lưu ý: Hash password nếu cần
                IsActive = true,
                IsOwner = false,
                StoreId = null
            });

            // D. Seed UserRole
            builder.Entity<UserRole>().HasData(new UserRole
            {
                UserId = superAdminUserId,
                RoleId = roleSuperAdminId
            });
        }
    }
}