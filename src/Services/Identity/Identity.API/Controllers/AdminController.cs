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
                var planName = "Chưa đăng ký"; // 1. Khai báo biến mới

                if (user.StoreId != null)
                {
                    // 2. Dùng Include để lấy kèm thông tin Gói cước
                    var store = await _context.Stores
                        .Include(s => s.SubscriptionPlan) 
                        .FirstOrDefaultAsync(s => s.Id == user.StoreId);

                    if (store != null) 
                    {
                        storeName = store.StoreName;
                        // 3. Lấy tên gói nếu có
                        if (store.SubscriptionPlan != null) 
                            planName = store.SubscriptionPlan.Name;
                    }
                }

                result.Add(new
                {
                    id = user.Id,
                    fullName = user.FullName,
                    email = user.Email,
                    storeName = storeName,// Hiển thị: "Vật Liệu Xây Dựng Ba Tèo"
                    planName = planName, // 👈 4. Nhớ thêm dòng này để trả về cho Frontend 
                    status = user.IsActive ? "Active" : "Locked"
                });
            }

            return Ok(result);
        }

        // ==========================================
        // API 2: Khóa/Mở khóa User (SỬA LẠI CHÚT CHO CHUẨN)
        // Frontend gọi: PUT /api/admin/users/{id}/status
        // ==========================================
        // API 2: Khóa/Mở khóa User (SỬA LẠI ĐỂ ĐỒNG BỘ VỚI STORE)
        [HttpPut("users/{id}/status")]
        public async Task<IActionResult> ToggleUserStatus(string id)
        {
            var user = await _userManager.FindByIdAsync(id);
            if (user == null) return NotFound("Không tìm thấy User này");

            // 1. Đảo trạng thái User (Khóa tài khoản đăng nhập)
            user.IsActive = !user.IsActive; 
            await _userManager.UpdateAsync(user);

            // 2. 👇 THÊM ĐOẠN NÀY: Đồng bộ trạng thái sang Cửa Hàng (Store)
            if (user.StoreId != null)
            {
                var store = await _context.Stores.FindAsync(user.StoreId);
                if (store != null)
                {
                    // Cửa hàng sẽ có trạng thái giống hệt chủ nhân
                    store.IsActive = user.IsActive; 
                    
                    // Cập nhật vào DB
                    _context.Stores.Update(store);
                    await _context.SaveChangesAsync();
                }
            }

            return Ok(new 
            { 
                message = user.IsActive ? "Đã mở khóa tài khoản và cửa hàng" : "Đã khóa tài khoản và cửa hàng", 
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

        // POST: /api/admin/owners
        [HttpPost("owners")]
        public async Task<IActionResult> CreateOwner([FromBody] CreateOwnerRequest request)
        {
            // 1. Tìm gói cước trong DB để lấy thông tin (Giá, thời hạn...)
            var plan = await _context.SubscriptionPlans.FindAsync(request.SubscriptionPlanId);
            if (plan == null) return BadRequest("Gói dịch vụ không tồn tại!");
            var newStore = new Store
            {
                Id = Guid.NewGuid(),
                StoreName = request.StoreName,
                Address = "Chưa cập nhật", 
                Phone = "",
                TaxCode = "",
                
                // 👇 Cập nhật thông tin gói cước
                SubscriptionPlanId = plan.Id,
                SubscriptionExpiryDate = DateTime.UtcNow.AddMonths(1), // Mặc định tặng 1 tháng dùng thử
                // 👇👇👇 THÊM 2 DÒNG NÀY CHO YÊN TÂM 👇👇👇
                IsActive = true, 
                CreatedAt = DateTime.UtcNow
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
        // GET: /api/admin/subscription-plans
        [HttpGet("subscription-plans")]
        public async Task<IActionResult> GetSubscriptionPlans()
        {
            var plans = await _context.SubscriptionPlans
                .Select(p => new 
                {
                    p.Id,
                    p.Name,
                    p.Price,
                    p.MaxEmployees,      
                    p.AllowAI,           
                    p.DurationInMonths,
                    // Tạo mô tả ngắn gọn để hiện lên Web
                    Description = $"Tối đa {p.MaxEmployees} nhân viên" + (p.AllowAI ? ", Có AI hỗ trợ" : "")
                })
                .ToListAsync();

            return Ok(plans);
        }
        // DELETE: /api/admin/users/{id}
        [HttpDelete("users/{id}")]
        public async Task<IActionResult> DeleteUser(string id)
        {
            var user = await _userManager.FindByIdAsync(id);
            if (user == null) return NotFound("Không tìm thấy người dùng");

            // ⚠️ CẢNH BÁO: Xóa Chủ hộ có thể cần xóa luôn Store (Cửa hàng)
            // Nếu bạn muốn xóa cả Store thì mở comment đoạn dưới ra:
            /*
            if (user.StoreId != null)
            {
                var store = await _context.Stores.FindAsync(user.StoreId);
                if (store != null) _context.Stores.Remove(store);
            }
            */

            var result = await _userManager.DeleteAsync(user);
            if (result.Succeeded) return Ok(new { message = "Xóa thành công!" });

            return BadRequest("Lỗi khi xóa người dùng");
        }
        // GET: /api/admin/dashboard-stats
            [HttpGet("dashboard-stats")]
            public async Task<IActionResult> GetDashboardStats()
            {
                // 1. Đếm số chủ hộ đang hoạt động (Dựa vào số Store Active)
                var activeOwnersCount = await _context.Stores.CountAsync(s => s.IsActive);

                // 2. Đếm số đăng ký mới trong tháng này
                // Lưu ý: Cần đảm bảo bảng Store của bạn có cột CreatedAt (hoặc tương đương)
                var now = DateTime.UtcNow;
                var startOfMonth = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);
                
                // Nếu bảng Store chưa có CreatedAt, bạn có thể tạm thời bỏ qua dòng này và trả về 0
                var newRegistrations = await _context.Stores
                    .CountAsync(s => s.CreatedAt >= startOfMonth);

                // 3. Tính Tổng Doanh Thu (Ước tính theo gói cước các Shop đang dùng)
                // Logic: Cộng tổng Price của tất cả SubscriptionPlan mà các Store đang Active sử dụng
                var totalRevenue = await _context.Stores
                    .Where(s => s.IsActive && s.SubscriptionPlanId != null)
                    .Include(s => s.SubscriptionPlan)
                    .SumAsync(s => s.SubscriptionPlan!.Price); // Dấu chấm than ! để báo compiler "Yên tâm, ko null đâu"
                return Ok(new 
                {
                    totalRevenue = totalRevenue,
                    activeOwners = activeOwnersCount,
                    newRegistrations = newRegistrations
                });
            }
    }
}