using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Identity.API.Data;
using Identity.Domain.Entities; // 👈 QUAN TRỌNG: Dùng User từ Domain mới
using Identity.API.Models;      // 👈 Để dùng CreateUserRequest (DTO)
using System.Linq;
using System.Threading.Tasks;

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
                    id = u.Id,          // 👈 Sửa thành chữ thường cho chuẩn JSON (Frontend thích điều này)
                    email = u.Email,
                    fullName = u.FullName,
                    
                    // 👇 QUAN TRỌNG: Lấy Role đầu tiên và đặt tên biến là "role" (viết thường)
                    // Logic: Nếu có role thì lấy tên, nếu không thì ghi "N/A"
                    // Dịch: Thử lấy Role đầu tiên, nếu có (?) thì lấy tên, nếu null (??) thì trả về "N/A"
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

            // 2. MẶC ĐỊNH LÀ EMPLOYEE (Không cần if/else phức tạp nữa)
            // Vì chức năng này là "Thêm nhân viên", nên chắc chắn vai trò là Employee
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
                    PasswordHash = request.Password, // Nhớ hash password sau này nhé
                    IsActive = true,
                    IsOwner = false,
                    // 👇 QUAN TRỌNG:
                    // Nếu người đang gọi API này là Owner (ông Ba Tèo), 
                    // thì nhân viên mới tạo ra PHẢI thuộc về Store của ông Ba Tèo.
                    // (Hiện tại bạn đang để null, tạm thời ok, nhưng sau này phải sửa chỗ này để lấy StoreId từ Token của người tạo)
                    StoreId = null 
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
    }
}