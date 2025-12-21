using Identity.API.Data; // 👈 Import DbContext
using Identity.API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Identity.API.Controllers
{
    [Route("api/users")]
    [ApiController]
    public class UsersController : ControllerBase
    {
        private readonly AppDbContext _context; // Dùng AppDbContext thay vì UserManager

        public UsersController(AppDbContext context)
        {
            _context = context;
        }

        // 1. GET: /api/users - Lấy danh sách nhân viên
        [HttpGet]
        public async Task<IActionResult> GetUsers()
        {
            var users = await _context.Users
                .Select(u => new 
                {
                    u.Id,
                    u.Email,
                    u.FullName,
                    u.Role,
                    Status = "Active" // Hardcode tạm
                })
                .ToListAsync();

            return Ok(users);
        }

        // 2. POST: /api/users - Tạo nhân viên mới
        [HttpPost]
        public async Task<IActionResult> CreateUser([FromBody] CreateUserRequest request)
        {
            // Kiểm tra xem email đã tồn tại chưa
            if (await _context.Users.AnyAsync(u => u.Email == request.Email))
            {
                return BadRequest(new { message = "Email này đã được sử dụng!" });
            }

            var user = new User
            {
                // ❌ BỎ DÒNG: UserName = request.Email, (Nguyên nhân lỗi)
                Email = request.Email,
                FullName = request.FullName,
                Role = request.Role,
                Password = request.Password // ⚠️ Lưu ý: Ở đây đang lưu password thô để khớp với data cũ của bạn
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Tạo nhân viên thành công!" });
        }
    }
}