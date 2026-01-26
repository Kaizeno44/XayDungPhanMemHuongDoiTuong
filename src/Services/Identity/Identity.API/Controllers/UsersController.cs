using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Identity; // 👈 Thêm using này
using Identity.API.Data;
using Identity.Domain.Entities; // 👈 QUAN TRỌNG: Dùng User từ Domain mới
using Identity.API.Models;      // 👈 Để dùng CreateUserRequest (DTO)
using System.Linq;
using System.Threading.Tasks;
using System; // Thêm System để dùng DateTime, Guid

namespace Identity.API.Controllers
{
    [Route("api/users")]
    [ApiController]
    public class UsersController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly UserManager<User> _userManager;
        private readonly RoleManager<Role> _roleManager;

        public UsersController(AppDbContext context, UserManager<User> userManager, RoleManager<Role> roleManager)
        {
            _context = context;
            _userManager = userManager;
            _roleManager = roleManager;
        }

        // 1. GET: /api/users - Lấy danh sách nhân viên
        [HttpGet]
        public async Task<IActionResult> GetUsers([FromQuery] Guid? storeId)
        {
            var query = _context.Users.AsQueryable();

            if (storeId.HasValue)
            {
                query = query.Where(u => u.StoreId == storeId.Value);
            }
            else
            {
                return Ok(new List<object>());
            }

            var users = await query
                // Join các bảng lại
                .Include(u => u.UserRoles)
                    .ThenInclude(ur => ur.Role)
                .Select(u => new 
                {
                    id = u.Id,          
                    email = u.Email,
                    fullName = u.FullName,
                    
                    // Logic: Nếu có role thì lấy tên, nếu không thì ghi "N/A"
                    role = u.UserRoles.Select(ur => ur.Role.Name).FirstOrDefault() ?? "N/A",                        
                    status = u.IsActive ? "Active" : "Inactive"
                })
                .ToListAsync();

            return Ok(users);
        }

        // 2. POST: /api/users - Tạo nhân viên mới
        [HttpPost]
        public async Task<IActionResult> CreateUser([FromBody] CreateUserRequest request)
        {
            // 1. Lấy StoreId từ Token của người tạo (Owner)
            var storeIdClaim = User.FindFirst("StoreId")?.Value;
            if (string.IsNullOrEmpty(storeIdClaim))
            {
                // Nếu không có trong token (có thể do chưa login hoặc token cũ), thử lấy từ tài khoản Nguyễn Văn Ba làm mặc định cho dev
                storeIdClaim = "404fb81a-d226-4408-9385-60f666e1c001";
            }

            // 2. Check trùng Email
            if (await _userManager.FindByEmailAsync(request.Email) != null)
            {
                return BadRequest(new { message = "Email này đã được sử dụng!" });
            }

            // 3. Tạo User object
            var user = new User
            {
                UserName = request.Email,
                Email = request.Email,
                FullName = request.FullName,
                IsActive = true,
                IsOwner = false,
                StoreId = Guid.Parse(storeIdClaim),
                EmailConfirmed = true
            };

            // 4. Sử dụng UserManager để tạo (Tự động Hash mật khẩu)
            var result = await _userManager.CreateAsync(user, request.Password);
            if (!result.Succeeded)
            {
                var errors = string.Join(", ", result.Errors.Select(e => e.Description));
                return BadRequest(new { message = "Lỗi tạo tài khoản: " + errors });
            }

            // 5. Gán Role Employee
            await _userManager.AddToRoleAsync(user, "Employee");

            return Ok(new { message = "Tạo nhân viên bán hàng thành công!" });
        }

        // ==========================================
        // 👇 3. NEW API: LƯU DEVICE TOKEN CHO FCM 👇
        // ==========================================
        // 4. DELETE: /api/users/{id} - Xóa nhân viên
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteUser(Guid id)
        {
            var user = await _context.Users
                .Include(u => u.UserRoles)
                .FirstOrDefaultAsync(u => u.Id == id);

            if (user == null)
            {
                return NotFound(new { message = "Không tìm thấy người dùng!" });
            }

            // Kiểm tra xem có phải là Owner không (Không cho phép xóa Owner qua API này)
            if (user.IsOwner)
            {
                return BadRequest(new { message = "Không thể xóa tài khoản Chủ cửa hàng!" });
            }

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // 1. Xóa các Role liên quan
                _context.UserRoles.RemoveRange(user.UserRoles);

                // 2. Xóa các Device Token liên quan
                var devices = await _context.UserDevices.Where(d => d.UserId == id).ToListAsync();
                _context.UserDevices.RemoveRange(devices);

                // 3. Xóa User
                _context.Users.Remove(user);

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return Ok(new { message = "Đã xóa nhân viên thành công!" });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, new { message = "Lỗi khi xóa: " + ex.Message });
            }
        }

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
