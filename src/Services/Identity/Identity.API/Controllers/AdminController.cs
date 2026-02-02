using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Identity.API.Data;
using Identity.Domain.Entities;
using Microsoft.AspNetCore.Identity; // <--- Nhớ thêm thư viện này
using System.Linq;
using System.Threading.Tasks;
using Identity.API.Models;
using Microsoft.Extensions.Caching.Distributed; // 👈 Thêm using cho Redis
namespace Identity.API.Controllers
{
    [Route("api/admin")]
    [ApiController]
    public class AdminController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly UserManager<User> _userManager;
        private readonly IDistributedCache _cache; // 👈 Inject Redis

        public AdminController(AppDbContext context, UserManager<User> userManager, IDistributedCache cache)
        {
            _context = context;
            _userManager = userManager;
            _cache = cache;
        }

        // ==========================================
        // API: Lấy thống kê tổng quan cho SuperAdmin
        // ==========================================
        [HttpGet("stats")]
        public async Task<IActionResult> GetAdminStats()
        {
            // 1. Lấy danh sách tất cả chủ hộ (Owner)
            var owners = await _userManager.GetUsersInRoleAsync("Owner");
            
            // Ensure owners is not null, though GetUsersInRoleAsync should return an empty list if no users are found.
            if (owners == null) owners = new List<User>();

#pragma warning disable CS8602 // Dereference of a possibly null reference.
#pragma warning disable CS8602 // Dereference of a possibly null reference.
            // 2. Tính số chủ hộ đang hoạt động
            var activeOwnersCount = owners.Count(u => u.IsActive);
#pragma warning restore CS8602 // Dereference of a possibly null reference.
#pragma warning restore CS8602 // Dereference of a possibly null reference.

#pragma warning disable CS8602 // Dereference of a possibly null reference.
            // 3. Tính số đăng ký mới trong tháng này
            var now = DateTime.UtcNow;
            var firstDayOfMonth = new DateTime(now.Year, now.Month, 1);
#pragma warning disable CS8602 // Dereference of a possibly null reference.
#pragma warning disable CS8602 // Dereference of a possibly null reference.
#pragma warning disable CS8602 // Dereference of a possibly null reference.
            var newRegistrationsCount = owners.Count(u => u.CreatedAt >= firstDayOfMonth);
#pragma warning restore CS8602 // Dereference of a possibly null reference.
#pragma warning restore CS8602 // Dereference of a possibly null reference.

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
                if (user.StoreId.HasValue)
                {
                    var store = await _context.Stores.FindAsync(user.StoreId.Value);
                    if (store != null) storeName = store.StoreName;
                }

                // Lấy thông tin gói cước
                var planName = "Chưa đăng ký";
                if (user.StoreId.HasValue)
                {
                    var store = await _context.Stores.Include(s => s.SubscriptionPlan).FirstOrDefaultAsync(s => s.Id == user.StoreId.Value);
                    if (store?.SubscriptionPlan != null) planName = store.SubscriptionPlan.Name;
                }

                result.Add(new
                {
                    id = user.Id,
                    fullName = user.FullName,
                    email = user.Email,
                    storeName = storeName, // Hiển thị: "Vật Liệu Xây Dựng Ba Tèo"
                    planName = planName,   // Hiển thị: "Gói Doanh Nghiệp (Pro)"
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
        // API: Xóa chủ hộ và cửa hàng
        // ==========================================
        [HttpDelete("owners/{id}")]
        public async Task<IActionResult> DeleteOwner(string id)
        {
            var user = await _userManager.FindByIdAsync(id);
            if (user == null) return NotFound("Không tìm thấy chủ hộ");

            if (!user.IsOwner) return BadRequest("Đây không phải là tài khoản chủ hộ");

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // 1. Xóa Store (Cascade sẽ xóa các liên kết khác nếu có)
                if (user.StoreId.HasValue)
                {
                    var store = await _context.Stores.FindAsync(user.StoreId.Value);
                    if (store != null) _context.Stores.Remove(store);
                }

                // 2. Xóa User
                await _userManager.DeleteAsync(user);

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return Ok(new { message = "Đã xóa chủ hộ và cửa hàng thành công!" });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, "Lỗi khi xóa: " + ex.Message);
            }
        }

        // ==========================================
        // API: Lấy trạng thái bảo trì
        // ==========================================
        [HttpGet("maintenance")]
        public async Task<IActionResult> GetMaintenanceStatus()
        {
            var status = await _cache.GetStringAsync("system_maintenance");
            return Ok(new { isMaintenance = status == "true" });
        }

        // ==========================================
        // API: Cập nhật trạng thái bảo trì
        // ==========================================
        [HttpPost("maintenance")]
        public async Task<IActionResult> SetMaintenanceStatus([FromBody] bool isMaintenance)
        {
            await _cache.SetStringAsync("system_maintenance", isMaintenance.ToString().ToLower());
            return Ok(new { message = isMaintenance ? "Đã bật chế độ bảo trì" : "Đã tắt chế độ bảo trì" });
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
                SubscriptionExpiryDate = DateTime.UtcNow.AddMonths(1), // Mặc định 1 tháng
                Users = new List<User>() // Initialize Users
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
                IsActive = true,
                UserRoles = new List<UserRole>() // Initialize UserRoles
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
