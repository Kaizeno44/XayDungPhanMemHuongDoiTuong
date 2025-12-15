using Microsoft.EntityFrameworkCore;
using Identity.API.Models;

namespace Identity.API.Data
{
    public class AppDbContext : DbContext
    {
        // 👇 QUAN TRỌNG: Phải có <AppDbContext> ở trong DbContextOptions
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
        {
        }

        public DbSet<User> Users { get; set; }
    }
}