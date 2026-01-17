using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
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

        public UsersController(AppDbContext context)
        {
            _context = context;
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
            // 1. Check trùng Email
            if (await _context.Users.AnyAsync(u => u.Email == request.Email))
            {
                return BadRequest(new { message = "Email này đã được sử dụng!" });
            }

            // 2. MẶC ĐỊNH LÀ EMPLOYEE 
            var roleName = "Employee"; 

            var role = await _context.Roles.FirstOrDefaultAsync(r => r.Name == roleName);
            if (role == null)
            {
                return StatusCode(500, "Lỗi hệ thống: Chưa cấu hình Role 'Employee' trong Database.");
            }

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // 3. Tạo User
                var user = new User
                {
                    Id = Guid.NewGuid(),
                    Email = request.Email,
                    FullName = request.FullName,
                    PasswordHash = request.Password, // Lưu ý: Nên hash password thực tế
                    IsActive = true,
                    IsOwner = false,
                    StoreId = null // TODO: Sau này lấy StoreId từ Token của người tạo (Owner)
                };

                _context.Users.Add(user);
                await _context.SaveChangesAsync();

                // 4. Gán Role Employee
                _context.UserRoles.Add(new UserRole 
                { 
                    UserId = user.Id, 
                    RoleId = role.Id 
                });
                
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return Ok(new { message = "Tạo nhân viên bán hàng thành công!" });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, "Lỗi: " + ex.Message);
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