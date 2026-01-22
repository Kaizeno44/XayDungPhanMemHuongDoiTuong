using BizFlow.ProductAPI.DbModels;
using Microsoft.EntityFrameworkCore;

namespace BizFlow.ProductAPI.Data
{
    public static class ProductDataSeeder
    {
        public static async Task SeedAsync(ProductDbContext context)
        {
            // 1. Đảm bảo Database đã được tạo
            // Lưu ý: EnsureCreatedAsync() không chạy Migrations. 
            // Nếu dùng Migrations thì nên dùng context.Database.MigrateAsync()
            await context.Database.EnsureCreatedAsync();

            // 2. Seed Categories (Danh mục)
            if (!await context.Categories.AnyAsync())
            {
                var cat1 = new Category { Name = "Vật liệu xây dựng", Code = "VL_XD" };
                var cat2 = new Category { Name = "Điện nước", Code = "DIEN_NUOC" };
                var cat3 = new Category { Name = "Sơn & Hóa chất", Code = "SON_HC" };
                
                context.Categories.AddRange(cat1, cat2, cat3);
                await context.SaveChangesAsync();

                // 3. Seed Products (Sản phẩm mẫu)
                var products = new List<Product>
                {
                    new Product { Name = "Tôn lạnh Hoa Sen 0.45mm", Sku = "TON-HS-045", CategoryId = cat1.Id, BaseUnit = "Tấm", Description = "Tôn lạnh chất lượng cao" },
                    new Product { Name = "Xi măng Hà Tiên PCB40", Sku = "XM-HT-PCB40", CategoryId = cat1.Id, BaseUnit = "Bao", Description = "Xi măng Hà Tiên đa dụng" },
                    new Product { Name = "Gạch ống 8x8x18", Sku = "GACH-ONG", CategoryId = cat1.Id, BaseUnit = "Viên", Description = "Gạch xây dựng tiêu chuẩn" },
                    new Product { Name = "Thép Pomina Phi 10", Sku = "THEP-P10", CategoryId = cat1.Id, BaseUnit = "Cây", Description = "Thép cuộn xây dựng" },
                    new Product { Name = "Ống nhựa Tiền Phong D21", Sku = "ONG-TP-D21", CategoryId = cat2.Id, BaseUnit = "Mét", Description = "Ống dẫn nước PVC" },
                    new Product { Name = "Dây điện Cadivi 2.5", Sku = "DAY-CV-25", CategoryId = cat2.Id, BaseUnit = "Cuộn", Description = "Dây điện lõi đồng" },
                    new Product { Name = "Sơn Dulux 5in1 Trắng", Sku = "SON-DX-W", CategoryId = cat3.Id, BaseUnit = "Thùng", Description = "Sơn nội thất cao cấp" }
                };

                context.Products.AddRange(products);
                await context.SaveChangesAsync();

                // 4. Seed Units & Inventory (Đơn vị & Tồn kho)
                foreach (var p in products)
                {
                    decimal price = 0;
                    if (p.Sku.Contains("TON")) price = 185000;
                    else if (p.Sku.Contains("XM")) price = 92000;
                    else if (p.Sku.Contains("GACH")) price = 1200;
                    else if (p.Sku.Contains("THEP")) price = 155000;
                    else if (p.Sku.Contains("ONG")) price = 12000;
                    else if (p.Sku.Contains("DAY")) price = 450000;
                    else if (p.Sku.Contains("SON")) price = 1250000;

                    context.ProductUnits.Add(new ProductUnit
                    {
                        ProductId = p.Id,
                        UnitName = p.BaseUnit,
                        ConversionValue = 1,
                        IsBaseUnit = true,
                        Price = price
                    });

                    context.Inventories.Add(new Inventory
                    {
                        ProductId = p.Id,
                        Quantity = 500,
                        LastUpdated = DateTime.UtcNow
                    });
                }
                await context.SaveChangesAsync();
            }
        }
    }
}
