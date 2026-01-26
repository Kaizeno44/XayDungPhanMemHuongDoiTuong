using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Identity.API.Data;
using Identity.Domain.Entities; // 👈 QUAN TRỌNG: Dùng User từ Domain mới
using Identity.API.Models;      // 👈 Để dùng CreateUserRequest (DTO)
using System.Linq;
using System.Threading.Tasks;
using System; // Thêm System để dùng DateTime, Guid
using Microsoft.AspNetCore.Identity; // 👈 QUAN TRỌNG: Thêm thư viện này
using System.Security.Claims; // 👈 BỔ SUNG DÒNG QUAN TRỌNG NÀY

namespace Identity.API.Controllers
{
    [Route("api/users")]
    [ApiController]
    public class UsersController : ControllerBase
    {
        private readonly AppDbContext _context;
// 👇 Khai báo thêm UserManager và RoleManager
        private readonly UserManager<User> _userManager;
        private readonly RoleManager<Role> _roleManager;
        // 👇 Inject vào Constructor
        public UsersController(AppDbContext context, UserManager<User> userManager, RoleManager<Role> roleManager)
        {
            _context = context;
            _userManager = userManager;
            _roleManager = roleManager;
        }
        // 1. GET: /api/users - Lấy danh sách nhân viên
        [HttpGet]
        public async Task<IActionResult> GetUsers()
        {
            var users = await _context.Users
                // Join các bảng lại
                .Include(u => u.UserRoles)
                    .ThenInclude(ur => ur.Role)
                .Select(u => new 
                {
                    id = u.Id,          
                    email = u.Email,
                    fullName = u.FullName,
                    storeId = u.StoreId, // Thêm cái này để debug xem nhân viên thuộc tiệm nào
                    // Logic: Lấy tên Role đầu tiên nếu có
                    role = u.UserRoles.Select(ur => ur.Role.Name).FirstOrDefault() ?? "N/A",                  
                    status = u.IsActive ? "Active" : "Inactive"
                })
                .ToListAsync();

            return Ok(users);
        }

        // 2. POST: /api/users - Tạo nhân viên mới
        // 2. POST: /api/users - Tạo nhân viên mới (ĐÃ SỬA LẠI CHUẨN)
        // 2. POST: /api/users - Tạo nhân viên mới (ĐÃ CÓ LOGIC CHẶN GÓI CƯỚC)
        [HttpPost]
        public async Task<IActionResult> CreateUser([FromBody] CreateUserRequest request)
        {
            // 1. Check trùng Email
            var existUser = await _userManager.FindByEmailAsync(request.Email);
            if (existUser != null) return BadRequest(new { message = "Email này đã được sử dụng!" });

            // 2. Check Role
            if (!await _roleManager.RoleExistsAsync("Employee"))
                return StatusCode(500, "Lỗi hệ thống: Role 'Employee' chưa được tạo.");

            // 3. Lấy thông tin Ông chủ & Cửa hàng
            var ownerId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var owner = await _userManager.FindByIdAsync(ownerId);
            
            if (owner == null) return Unauthorized("Không tìm thấy thông tin người tạo.");

            // 👇👇👇 LOGIC KIỂM TRA GIỚI HẠN GÓI CƯỚC (START-UP vs PRO) 👇👇👇
            var store = await _context.Stores
                .Include(s => s.SubscriptionPlan)
                .FirstOrDefaultAsync(s => s.Id == owner.StoreId);

            if (store != null && store.SubscriptionPlan != null)
            {
                int maxEmployees = store.SubscriptionPlan.MaxEmployees;
                
                // Nếu > 0 thì mới kiểm tra (0 là không giới hạn)
                if (maxEmployees > 0)
                {
                    int currentCount = await _context.Users.CountAsync(u => u.StoreId == owner.StoreId);
                    if (currentCount >= maxEmployees)
                    {
                        return BadRequest(new { 
                            message = $"Gói '{store.SubscriptionPlan.Name}' chỉ cho phép tối đa {maxEmployees} nhân viên. Vui lòng nâng cấp gói cước!" 
                        });
                    }
                }
            }
            // 👆👆👆 KẾT THÚC LOGIC KIỂM TRA 👆👆👆

            // 4. Tạo User
            var user = new User
            {
                UserName = request.Email,
                Email = request.Email,
                FullName = request.FullName,
                IsActive = true,
                IsOwner = false,
                StoreId = owner.StoreId // Gán nhân viên vào đúng cửa hàng của ông chủ
            };

            var result = await _userManager.CreateAsync(user, request.Password);

            if (result.Succeeded)
            {
                await _userManager.AddToRoleAsync(user, "Employee");
                return Ok(new { message = "Tạo nhân viên bán hàng thành công!" });
            }
            else
            {
                return BadRequest(new { message = "Tạo thất bại", errors = result.Errors });
            }
        }
        // ==========================================
        // 👇 3. NEW API: LƯU DEVICE TOKEN CHO FCM 👇
        // ==========================================
        [HttpPost("device-token")]
        public async Task<IActionResult> SaveDeviceToken([FromBody] SaveDeviceTokenRequest request)
        {
            // Validation cơ bản
            if (string.IsNullOrEmpty(request.DeviceToken))
            {
                return BadRequest(new { message = "Device Token không được để trống" });
            }

            try 
            {
                // 1. Kiểm tra xem Token này đã tồn tại với User này chưa
                var existingDevice = await _context.UserDevices
                    .FirstOrDefaultAsync(d => d.DeviceToken == request.DeviceToken && d.UserId == request.UserId);

                if (existingDevice == null)
                {
                    // 2. Nếu chưa có -> Tạo mới
                    var newDevice = new UserDevice
                    {
                        Id = Guid.NewGuid(),
                        UserId = request.UserId,
                        DeviceToken = request.DeviceToken,
                        Platform = request.Platform ?? "Android", // Mặc định là Android nếu null
                        LastActiveAt = DateTime.UtcNow
                    };

                    _context.UserDevices.Add(newDevice);
                    await _context.SaveChangesAsync();
                    
                    return Ok(new { message = "Đã lưu Device Token thành công (New)!" });
                }
                else
                {
                    // 3. Nếu có rồi -> Update thời gian online (Active)
                    existingDevice.LastActiveAt = DateTime.UtcNow;
                    // Cập nhật lại platform phòng trường hợp user đổi máy nhưng dùng lại backup cũ
                    existingDevice.Platform = request.Platform ?? existingDevice.Platform;
                    
                    await _context.SaveChangesAsync();
                    
                    return Ok(new { message = "Device Token đã tồn tại, cập nhật trạng thái Active." });
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi lưu token: " + ex.Message });
            }
        }
    }

    // 👇 DTO Class (Đặt ở đây cho tiện hoặc chuyển sang folder Models)
    public class SaveDeviceTokenRequest
    {
        public Guid UserId { get; set; }
        public string DeviceToken { get; set; }
        public string? Platform { get; set; } // "android", "ios", "web"
    }
}