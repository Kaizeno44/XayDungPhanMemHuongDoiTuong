using Identity.API.Data;
using Identity.Domain.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using FirebaseAdmin.Messaging; 

namespace Identity.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class NotificationsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public NotificationsController(AppDbContext context)
        {
            _context = context;
        }

        [HttpPost("register-token")]
        public async Task<IActionResult> RegisterDeviceToken([FromBody] RegisterTokenRequest request)
        {
            var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdString))
            {
                return Unauthorized("Không tìm thấy User ID trong Token. Vui lòng đăng nhập lại.");
            }

            var userId = Guid.Parse(userIdString);
            
            var existingDevice = await _context.UserDevices
                .FirstOrDefaultAsync(d => d.DeviceToken == request.DeviceToken && d.UserId == userId);

            if (existingDevice == null)
            {
                // Tạo mới
                _context.UserDevices.Add(new UserDevice
                {
                    UserId = userId,
                    DeviceToken = request.DeviceToken,
                    // 👇 SỬA LỖI TẠI ĐÂY: Dùng LastActiveAt thay vì LastUpdated
                    LastActiveAt = DateTime.UtcNow,
                    Platform = "Android" // Giá trị mặc định
                });
            }
            else
            {
                // Cập nhật
                // 👇 SỬA LỖI TẠI ĐÂY: Dùng LastActiveAt thay vì LastUpdated
                existingDevice.LastActiveAt = DateTime.UtcNow; 
            }

            await _context.SaveChangesAsync();
            return Ok(new { Message = "Đã lưu Device Token thành công" });
        }
    }

    public class RegisterTokenRequest
    {
        public string DeviceToken { get; set; }
    }
}