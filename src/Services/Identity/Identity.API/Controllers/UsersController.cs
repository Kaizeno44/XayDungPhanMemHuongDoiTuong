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
            // Logic mới: Phải JOIN bảng UserRoles và Role để lấy tên quyền
            var users = await _context.Users
                .Include(u => u.UserRoles)
                    .ThenInclude(ur => ur.Role)
                .Select(u => new 
                {
                    u.Id,
                    u.Email,
                    u.FullName,
                    // Lấy danh sách Role (Vì cấu trúc mới 1 người có thể nhiều quyền)
                    Roles = u.UserRoles.Select(ur => ur.Role.Name).ToList(),
                    Status = u.IsActive ? "Active" : "Inactive"
                })
                .ToListAsync();

            return Ok(users);
        }

        // 2. POST: /api/users - Tạo nhân viên mới
        [HttpPost]
        public async Task<IActionResult> CreateUser([FromBody] CreateUserRequest request)
        {
            // A. Kiểm tra email trùng
            if (await _context.Users.AnyAsync(u => u.Email == request.Email))
            {
                return BadRequest(new { message = "Email này đã được sử dụng!" });
            }

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // B. Tạo User mới (Theo chuẩn Entity mới)
                var user = new User
                {
                    Id = Guid.NewGuid(),
                    Email = request.Email,
                    FullName = request.FullName,
                    PasswordHash = request.Password, // Lưu ý: Thực tế hãy Hash password tại đây
                    IsActive = true,
                    IsOwner = false, // Nhân viên thì không phải chủ shop
                    StoreId = null   // Tạm thời null, sau này Admin sẽ gán vào Store
                };

                _context.Users.Add(user);
                await _context.SaveChangesAsync();

                // C. Tìm Role tương ứng trong DB (Ví dụ: "Employee")
                // Nếu request không gửi Role thì mặc định là Employee
                var roleName = string.IsNullOrEmpty(request.Role) ? "Employee" : request.Role;
                var role = await _context.Roles.FirstOrDefaultAsync(r => r.Name == roleName);

                if (role != null)
                {
                    // D. Gán Role cho User (Tạo bản ghi trong bảng trung gian)
                    _context.UserRoles.Add(new UserRole 
                    { 
                        UserId = user.Id, 
                        RoleId = role.Id 
                    });
                    await _context.SaveChangesAsync();
                }

                await transaction.CommitAsync();
                return Ok(new { message = "Tạo nhân viên thành công!" });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, "Lỗi khi tạo user: " + ex.Message);
            }
        }
    }
}