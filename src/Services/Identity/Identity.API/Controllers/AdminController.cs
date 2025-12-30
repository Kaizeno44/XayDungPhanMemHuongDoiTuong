using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Identity.API.Data;
using Identity.Domain.Entities;
using System.Linq;
using System.Threading.Tasks;

namespace Identity.API.Controllers
{
    [Route("api/admin")]
    [ApiController]
    public class AdminController : ControllerBase
    {
        private readonly AppDbContext _context;

        public AdminController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/admin/tenants
        [HttpGet("tenants")]
        public async Task<IActionResult> GetAllTenants()
        {
            var tenants = await _context.Stores
                .Include(s => s.SubscriptionPlan) 
                .Include(s => s.Users)            
                .Select(s => new 
                {
                    StoreId = s.Id,
                    StoreName = s.StoreName,
                    Phone = s.Phone,
                    Address = s.Address,
                    TaxCode = s.TaxCode,
                    
                    PlanName = s.SubscriptionPlan != null ? s.SubscriptionPlan.Name : "Chưa đăng ký",
                    
                    // 👇 GIẢI PHÁP SỬA LỖI TRIỆT ĐỂ (Dòng vàng biến mất 100%)
                    // Logic: Lọc ông chủ -> Chỉ lấy cái Tên -> Lấy cái đầu tiên -> Nếu null thì lấy text mặc định
                    OwnerName = s.Users.Where(u => u.IsOwner)
                                       .Select(u => u.FullName)
                                       .FirstOrDefault() ?? "Chưa có chủ",

                    UserCount = s.Users.Count,
                    ExpiryDate = s.SubscriptionExpiryDate
                })
                .ToListAsync();

            return Ok(tenants);
        }

        // POST: api/admin/users/{id}/toggle-active
        [HttpPost("users/{id}/toggle-active")]
        public async Task<IActionResult> ToggleUserActive(Guid id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null) return NotFound("Không tìm thấy User này");

            user.IsActive = !user.IsActive;
            await _context.SaveChangesAsync();

            return Ok(new 
            { 
                Message = user.IsActive ? "Đã mở khóa tài khoản" : "Đã khóa tài khoản", 
                Status = user.IsActive 
            });
        }
    }
}