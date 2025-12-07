using Identity.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace Identity.Infrastructure.Persistence
{
    public class IdentityDbContext : DbContext
    {
        public IdentityDbContext(DbContextOptions<IdentityDbContext> options) : base(options)
        {
        }

        // 1. Khai báo các bảng (DbSet)
        public DbSet<User> Users { get; set; }
        public DbSet<Role> Roles { get; set; }
        public DbSet<UserRole> UserRoles { get; set; }
        
        // --- THÊM MỚI 2 BẢNG NÀY ---
        public DbSet<Store> Stores { get; set; }
        public DbSet<SubscriptionPlan> SubscriptionPlans { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // --- Cấu hình UserRole (Giữ nguyên) ---
            modelBuilder.Entity<UserRole>()
                .HasKey(ur => new { ur.UserId, ur.RoleId });

            modelBuilder.Entity<UserRole>()
                .HasOne(ur => ur.User)
                .WithMany(u => u.UserRoles)
                .HasForeignKey(ur => ur.UserId);

            modelBuilder.Entity<UserRole>()
                .HasOne(ur => ur.Role)
                .WithMany(r => r.UserRoles)
                .HasForeignKey(ur => ur.RoleId);

            // --- THAY ĐỔI LỚN: CẤU HÌNH QUAN HỆ MỚI ---

            // 1. Quan hệ Store - User (1 Cửa hàng có nhiều User)
            modelBuilder.Entity<User>()
                .HasOne(u => u.Store)
                .WithMany(s => s.Users)
                .HasForeignKey(u => u.StoreId)
                .OnDelete(DeleteBehavior.Restrict); // Xóa Store không tự xóa User (để an toàn dữ liệu)

            // 2. Quan hệ Store - SubscriptionPlan (1 Gói cước áp dụng cho nhiều Cửa hàng)
            modelBuilder.Entity<Store>()
                .HasOne(s => s.SubscriptionPlan)
                .WithMany() // Bên Plan không cần giữ list Store nên để trống
                .HasForeignKey(s => s.SubscriptionPlanId)
                .OnDelete(DeleteBehavior.Restrict); // Xóa Gói cước không được xóa Cửa hàng đang dùng
            
            // 3. Cấu hình giá trị mặc định (Optional)
            modelBuilder.Entity<SubscriptionPlan>()
                .Property(p => p.Price)
                .HasColumnType("decimal(18,2)"); // Định dạng tiền tệ
        }
    }
}