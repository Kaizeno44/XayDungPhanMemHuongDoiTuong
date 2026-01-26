using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Identity.API.Data;
using Identity.Domain.Entities;
using Microsoft.AspNetCore.Identity; // <--- Nhớ thêm thư viện này
using System.Linq;
using System.Threading.Tasks;
using Identity.API.Models;
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
        // API: Lấy thống kê tổng quan cho SuperAdmin
        // ==========================================
        [HttpGet("stats")]
        public async Task<IActionResult> GetAdminStats()
        {
            // 1. Lấy danh sách tất cả chủ hộ (Owner)
            var owners = await _userManager.GetUsersInRoleAsync("Owner");
            
            // 2. Tính số chủ hộ đang hoạt động
            var activeOwnersCount = owners.Count(u => u.IsActive);

            // 3. Tính số đăng ký mới trong tháng này
            var now = DateTime.UtcNow;
            var firstDayOfMonth = new DateTime(now.Year, now.Month, 1);
            var newRegistrationsCount = owners.Count(u => u.CreatedAt >= firstDayOfMonth);

            // 4. Tính tổng doanh thu từ gói cước
            // Lấy tất cả các Store có gán gói cước và tính tổng Price
            var totalRevenue = await _context.Stores
                .Include(s => s.SubscriptionPlan)
                .Where(s => s.SubscriptionPlanId != null)
                .SumAsync(s => s.SubscriptionPlan.Price);

            // 5. Tính toán thay đổi so với tháng trước
            var lastMonth = now.AddMonths(-1);
            var firstDayOfLastMonth = new DateTime(lastMonth.Year, lastMonth.Month, 1);

            // A. Thay đổi số lượng chủ hộ (So với tháng trước)
            var ownersLastMonth = owners.Count(u => u.CreatedAt < firstDayOfMonth);
            var ownersChange = owners.Count - ownersLastMonth;
            var ownersChangeText = ownersChange >= 0 ? $"+{ownersChange}" : ownersChange.ToString();

            // B. Thay đổi số lượng đăng ký mới (So với tháng trước)
            var lastMonthRegistrations = owners.Count(u => u.CreatedAt >= firstDayOfLastMonth && u.CreatedAt < firstDayOfMonth);
            var registrationChange = newRegistrationsCount - lastMonthRegistrations;
            var registrationChangeText = registrationChange >= 0 ? $"+{registrationChange}" : registrationChange.ToString();

            // C. Thay đổi doanh thu (Giả lập dựa trên tỷ lệ tăng trưởng chủ hộ)
            decimal revenueChangePercent = 0;
            if (totalRevenue > 0 && ownersLastMonth > 0) {
                revenueChangePercent = (decimal)ownersChange / ownersLastMonth * 100;
            }
            var revenueChangeText = revenueChangePercent >= 0 ? $"+{revenueChangePercent:N1}%" : $"{revenueChangePercent:N1}%";

            return Ok(new
            {
                totalRevenue = totalRevenue,
                activeOwners = activeOwnersCount,
                newRegistrations = newRegistrationsCount,
                revenueChange = revenueChangeText,
                ownersChange = ownersChangeText,
                registrationsChange = registrationChangeText
            });
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
        // API: Lấy danh sách gói cước
        // ==========================================
        [HttpGet("plans")]
        public async Task<IActionResult> GetPlans()
        {
            var plans = await _context.SubscriptionPlans.ToListAsync();
            return Ok(plans);
        }

        // ==========================================
        // API: Cập nhật gói cước
        // ==========================================
        [HttpPut("plans/{id}")]
        public async Task<IActionResult> UpdatePlan(Guid id, [FromBody] SubscriptionPlan request)
        {
            var plan = await _context.SubscriptionPlans.FindAsync(id);
            if (plan == null) return NotFound("Không tìm thấy gói cước");

            plan.Price = request.Price;
            plan.MaxEmployees = request.MaxEmployees;
            plan.Name = request.Name;
            plan.DurationInMonths = request.DurationInMonths;
            plan.AllowAI = request.AllowAI;

            await _context.SaveChangesAsync();
            return Ok(new { message = "Cập nhật gói cước thành công!" });
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

        // POST: /api/admin/owners
        [HttpPost("owners")]
        public async Task<IActionResult> CreateOwner([FromBody] CreateOwnerRequest request)
        {
            // 1. Tạo Store (Chỉ điền các trường có trong Store.cs)
            var newStore = new Store
            {
                Id = Guid.NewGuid(),
                StoreName = request.StoreName,
                
                // Vì trong Store.cs các trường này là string (không null)
                // nên ta phải gán giá trị mặc định để không bị lỗi CS8618
                Address = "Chưa cập nhật", 
                Phone = "",
                TaxCode = "",
                
                // Gán gói cước đã chọn
                SubscriptionPlanId = request.SubscriptionPlanId, 
                SubscriptionExpiryDate = DateTime.UtcNow.AddMonths(1) // Mặc định 1 tháng
            };

            _context.Stores.Add(newStore);
            await _context.SaveChangesAsync();

            // 2. Tạo User (Code giữ nguyên)
            var newUser = new User
            {
                UserName = request.Email,
                Email = request.Email,
                FullName = request.FullName, // Nhớ dòng này
                StoreId = newStore.Id,
                IsActive = true 
            };

            var result = await _userManager.CreateAsync(newUser, request.Password);

            if (result.Succeeded)
            {
                await _userManager.AddToRoleAsync(newUser, "Owner");
                return Ok(new { message = "Tạo chủ hộ thành công!" });
            }
            else
            {
                // Rollback: Xóa Store nếu tạo User thất bại
                _context.Stores.Remove(newStore);
                await _context.SaveChangesAsync();
                return BadRequest(result.Errors);
            }
        }
    }
}
