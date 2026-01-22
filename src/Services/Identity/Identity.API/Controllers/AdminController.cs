using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Identity.API.Data;
using Identity.Domain.Entities;
using Microsoft.AspNetCore.Identity; // <--- Nhớ thêm thư viện này
using System.Linq;
using System.Threading.Tasks;

namespace Identity.API.Controllers
{
    [Route("api/admin")]
    [ApiController]
    public class AdminController : ControllerBase
    {
        private readonly AppDbContext _context;
        // Thêm UserManager để quản lý User
        private readonly UserManager<User> _userManager; 

        // Inject thêm UserManager vào Constructor
        public AdminController(AppDbContext context, UserManager<User> userManager)
        {
            _context = context;
            _userManager = userManager;
        }

        // ==========================================
        // API 1: Lấy danh sách USER theo Role (CẦN THÊM CÁI NÀY)
        // Frontend gọi: GET /api/admin/users?role=Owner
        // ==========================================
        [HttpGet("users")]
        public async Task<IActionResult> GetUsersByRole([FromQuery] string role)
        {
            // 1. Lấy danh sách User thuộc Role (ví dụ "Owner")
            var users = await _userManager.GetUsersInRoleAsync(role);

            // 2. Map dữ liệu trả về
            var result = new List<object>();
            foreach (var user in users)
            {
                // Lấy tên cửa hàng nếu có
                var storeName = "Chưa có cửa hàng";
                if (user.StoreId != null)
                {
                    var store = await _context.Stores.FindAsync(user.StoreId);
                    if (store != null) storeName = store.StoreName;
                }

                result.Add(new
                {
                    id = user.Id,
                    fullName = user.FullName,
                    email = user.Email,
                    storeName = storeName, // Hiển thị: "Vật Liệu Xây Dựng Ba Tèo"
                    status = user.IsActive ? "Active" : "Locked"
                });
            }

            return Ok(result);
        }

        // ==========================================
        // API 2: Khóa/Mở khóa User (SỬA LẠI CHÚT CHO CHUẨN)
        // Frontend gọi: PUT /api/admin/users/{id}/status
        // ==========================================
        [HttpPut("users/{id}/status")] // Đổi thành PUT cho đúng chuẩn REST
        public async Task<IActionResult> ToggleUserStatus(string id)
        {
            var user = await _userManager.FindByIdAsync(id);
            if (user == null) return NotFound("Không tìm thấy User này");

            user.IsActive = !user.IsActive; // Đảo ngược trạng thái
            await _userManager.UpdateAsync(user);

            return Ok(new 
            { 
                message = user.IsActive ? "Đã mở khóa tài khoản" : "Đã khóa tài khoản", 
                newStatus = user.IsActive 
            });
        }

        // ==========================================
        // API 3: Lấy danh sách Tenant (GIỮ NGUYÊN CỦA BẠN - Rất tốt)
        // Dùng cho trang "Quản lý Cửa hàng" sau này
        // ==========================================
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
                    OwnerName = s.Users.Where(u => u.IsOwner)
                                       .Select(u => u.FullName)
                                       .FirstOrDefault() ?? "Chưa có chủ",
                    UserCount = s.Users.Count,
                    ExpiryDate = s.SubscriptionExpiryDate
                })
                .ToListAsync();

            return Ok(tenants);
        }
    }
}