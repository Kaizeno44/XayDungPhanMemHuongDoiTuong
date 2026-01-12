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
                var category = new Category
                {
                    Name = "Vật liệu xây dựng",
                    Code = "VL_XD"
                };
                context.Categories.Add(category);
                await context.SaveChangesAsync();

                // 3. Seed Products (Sản phẩm mẫu)
                if (!await context.Products.AnyAsync())
                {
                    var products = new List<Product>
                    {
                        new Product
                        {
                            Name = "Tôn lạnh mạ màu Hoa Sen 0.45mm",
                            Sku = "TON-HS-045",
                            CategoryId = category.Id,
                            BaseUnit = "Tấm",
                            ImageUrl = "https://example.com/images/ton-lanh.png",
                            Description = "Tôn lạnh chất lượng cao từ tập đoàn Hoa Sen"
                        },
                        new Product
                        {
                            Name = "Xi măng Hà Tiên PCB40",
                            Sku = "XM-HT-PCB40",
                            CategoryId = category.Id,
                            BaseUnit = "Bao",
                            ImageUrl = "https://example.com/images/xi-mang.png",
                            Description = "Xi măng Hà Tiên đa dụng"
                        }
                    };

                    context.Products.AddRange(products);
                    await context.SaveChangesAsync();

                    // 4. Seed Units & Inventory (Đơn vị & Tồn kho)
                    foreach (var p in products)
                    {
                        // Thêm đơn vị cơ bản
                        context.ProductUnits.Add(new ProductUnit
                        {
                            ProductId = p.Id,
                            UnitName = p.BaseUnit,
                            ConversionValue = 1,
                            IsBaseUnit = true,
                            Price = p.Sku.Contains("TON") ? 185000 : 90000
                        });

                        // Thêm tồn kho ban đầu
                        context.Inventories.Add(new Inventory
                        {
                            ProductId = p.Id,
                            Quantity = 100,
                            LastUpdated = DateTime.UtcNow
                        });
                    }
                    await context.SaveChangesAsync();
                }
            }
        }
    }
}
