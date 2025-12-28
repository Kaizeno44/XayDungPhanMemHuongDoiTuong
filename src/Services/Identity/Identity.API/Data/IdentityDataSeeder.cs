using Identity.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace Identity.API.Data
{
    public static class IdentityDataSeeder
    {
        public static async Task SeedAsync(AppDbContext context)
        {
            if (await context.Stores.AnyAsync()) return;

            // --- TẠO CỬA HÀNG 1: VLXD BA TÈO ---
            var proPlanId = Guid.Parse("60350d5e-d225-4676-9051-512686851234");
            var store1 = new Store
            {
                Id = Guid.NewGuid(),
                StoreName = "VLXD Ba Tèo",
                Address = "123 Đường Láng, Hà Nội",
                Phone = "0909123456",
                // 👇 THÊM DÒNG NÀY ĐỂ SỬA LỖI
                TaxCode = "0101234567", 
                SubscriptionPlanId = proPlanId,
                SubscriptionExpiryDate = DateTime.UtcNow.AddMonths(12)
            };
            context.Stores.Add(store1);

            // Tạo ông chủ Ba Tèo
            var owner1 = new User
            {
                Id = Guid.NewGuid(),
                Email = "bateo@bizflow.com",
                FullName = "Nguyễn Văn Tèo",
                PasswordHash = "123456",
                IsActive = true,
                IsOwner = true,
                StoreId = store1.Id
            };
            context.Users.Add(owner1);

            var roleOwner = await context.Roles.FirstAsync(r => r.Name == "Owner");
            context.UserRoles.Add(new UserRole { UserId = owner1.Id, RoleId = roleOwner.Id });

            var emp1 = new User
            {
                Id = Guid.NewGuid(),
                Email = "nv_bateo@bizflow.com",
                FullName = "Nhân Viên A",
                PasswordHash = "123456",
                IsActive = true,
                IsOwner = false,
                StoreId = store1.Id
            };
            context.Users.Add(emp1);
            
            var roleEmp = await context.Roles.FirstAsync(r => r.Name == "Employee");
            context.UserRoles.Add(new UserRole { UserId = emp1.Id, RoleId = roleEmp.Id });


            // --- TẠO CỬA HÀNG 2: ĐIỆN NƯỚC TƯ TÍ ---
            var basicPlanId = Guid.Parse("d5093c85-64e6-42c2-8098-902341270123");
            var store2 = new Store
            {
                Id = Guid.NewGuid(),
                StoreName = "Điện Nước Tư Tí",
                Address = "456 Cầu Giấy",
                Phone = "0912345678",
                // 👇 THÊM DÒNG NÀY NỮA
                TaxCode = "0108889999", 
                SubscriptionPlanId = basicPlanId,
                SubscriptionExpiryDate = DateTime.UtcNow.AddMonths(1)
            };
            context.Stores.Add(store2);

            var owner2 = new User
            {
                Id = Guid.NewGuid(),
                Email = "tuti@bizflow.com",
                FullName = "Trần Văn Tí",
                PasswordHash = "123456",
                IsActive = true,
                IsOwner = true,
                StoreId = store2.Id
            };
            context.Users.Add(owner2);
            context.UserRoles.Add(new UserRole { UserId = owner2.Id, RoleId = roleOwner.Id });

            await context.SaveChangesAsync();
        }
    }
}