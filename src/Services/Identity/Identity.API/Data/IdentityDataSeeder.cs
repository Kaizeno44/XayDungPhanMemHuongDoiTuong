using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Identity.Domain.Entities;
using Identity.API.Data;

namespace Identity.API.Data
{
    public static class IdentityDataSeeder
    {
        public static async Task SeedAsync(Identity.API.Data.AppDbContext context, UserManager<User> userManager, RoleManager<Role> roleManager)
        {
            // ------------------------------------------------------------
            // 1. TẠO GÓI DỊCH VỤ (SUBSCRIPTION PLANS)
            // ------------------------------------------------------------
            var basicPlanId = Guid.Parse("d5093c85-64e6-42c2-8098-902341270123");
            var proPlanId = Guid.Parse("60350d5e-d225-4676-9051-512686851234");

            if (!await context.SubscriptionPlans.AnyAsync())
            {
                var plans = new List<SubscriptionPlan>
                {
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
                };
                await context.SubscriptionPlans.AddRangeAsync(plans);
                await context.SaveChangesAsync();
            }

            // ------------------------------------------------------------
            // 2. TẠO QUYỀN (ROLES)
            // ------------------------------------------------------------
            string[] roles = { "SuperAdmin", "Owner", "Employee" };
            foreach (var roleName in roles)
            {
                if (!await roleManager.RoleExistsAsync(roleName))
                {
                    await roleManager.CreateAsync(new Role 
                    { 
                        Name = roleName, 
                        Description = $"Vai trò {roleName} trong hệ thống" 
                    });
                }
            }

            // ------------------------------------------------------------
            // 3. TẠO SUPER ADMIN (Quản trị viên hệ thống)
            // ------------------------------------------------------------
            var adminEmail = "superadmin@bizflow.com";
            if (await userManager.FindByEmailAsync(adminEmail) == null)
            {
                var adminUser = new User
                {
                    UserName = adminEmail,
                    Email = adminEmail,
                    FullName = "Quản Trị Viên Hệ Thống",
                    IsActive = true,
                    IsOwner = false,
                    EmailConfirmed = true
                };
                var result = await userManager.CreateAsync(adminUser, "Admin@123");
                if (result.Succeeded) await userManager.AddToRoleAsync(adminUser, "SuperAdmin");
            }

            // ------------------------------------------------------------
            // 4. TẠO CỬA HÀNG MẪU (STORE)
            // ------------------------------------------------------------
            var sampleStoreName = "Vật Liệu Xây Dựng Ba Tèo";
            var sampleStore = await context.Stores.FirstOrDefaultAsync(s => s.StoreName == sampleStoreName);
            
            if (sampleStore == null)
            {
                sampleStore = new Store
                {
                    Id = Guid.Parse("d2708c0c-847e-468e-976e-5776d5483033"),
                    StoreName = sampleStoreName,
                    Address = "123 Đường Láng, Hà Nội",
                    Phone = "0987654321",
                    TaxCode = "0101234567",
                    SubscriptionPlanId = proPlanId, // Cho dùng gói xịn nhất
                    SubscriptionExpiryDate = DateTime.UtcNow.AddYears(1)
                };
                await context.Stores.AddAsync(sampleStore);
                await context.SaveChangesAsync(); // Lưu Store trước để có ID gán cho User
            }

            // ------------------------------------------------------------
            // 5. TẠO OWNER (CHỦ CỬA HÀNG BA TÈO)
            // ------------------------------------------------------------
            var ownerEmail = "owner@bizflow.com";
            if (await userManager.FindByEmailAsync(ownerEmail) == null)
            {
                var ownerUser = new User
                {
                    UserName = ownerEmail,
                    Email = ownerEmail,
                    FullName = "Nguyễn Văn Ba (Chủ Shop)",
                    IsActive = true,
                    IsOwner = true,
                    EmailConfirmed = true,
                    StoreId = sampleStore.Id // Gán vào cửa hàng Ba Tèo
                };
                var result = await userManager.CreateAsync(ownerUser, "Admin@123");
                if (result.Succeeded) await userManager.AddToRoleAsync(ownerUser, "Owner");
            }

            // ------------------------------------------------------------
            // 6. TẠO EMPLOYEE (NHÂN VIÊN CỬA HÀNG BA TÈO)
            // ------------------------------------------------------------
            var staffEmail = "staff@bizflow.com";
            if (await userManager.FindByEmailAsync(staffEmail) == null)
            {
                var staffUser = new User
                {
                    UserName = staffEmail,
                    Email = staffEmail,
                    FullName = "Trần Thị Bé (Nhân viên)",
                    IsActive = true,
                    IsOwner = false,
                    EmailConfirmed = true,
                    StoreId = sampleStore.Id // Gán vào cửa hàng Ba Tèo
                };
                var result = await userManager.CreateAsync(staffUser, "Admin@123");
                if (result.Succeeded) await userManager.AddToRoleAsync(staffUser, "Employee");
            }

            // ------------------------------------------------------------
            // 7. TẠO DỮ LIỆU SỔ CÁI MẪU (LEDGER) - Đã xóa theo yêu cầu
            // ------------------------------------------------------------
            /*
            if (!await context.Ledgers.AnyAsync() && sampleStore != null)
            {
                // ...
            }
            */

            // Đồng bộ StoreId cho Nguyễn Văn Ba (Sử dụng mã ID thực tế đang hoạt động)
            var baStoreId = Guid.Parse("404fb81a-d226-4408-9385-60f666e1c001");
            var baUser = await userManager.FindByEmailAsync("owner@bizflow.com");
            
            if (baUser != null && baUser.StoreId != baStoreId) {
                baUser.StoreId = baStoreId;
                await userManager.UpdateAsync(baUser);
                Console.WriteLine($"--> System: Reverted Nguyễn Văn Ba to StoreId: {baStoreId}");
            }
        }
    }
}
