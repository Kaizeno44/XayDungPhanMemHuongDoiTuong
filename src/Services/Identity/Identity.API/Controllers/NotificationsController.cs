using Identity.API.Data;
using Identity.Domain.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using FirebaseAdmin.Messaging; // Dùng cho hàm Send ở dưới

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
            // 1. Lấy chuỗi ID ra trước (có thể là null)
            var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            // 2. Kiểm tra nếu null thì chặn lại ngay
            if (string.IsNullOrEmpty(userIdString))
            {
                return Unauthorized("Không tìm thấy User ID trong Token. Vui lòng đăng nhập lại.");
            }

            // 3. Nếu có dữ liệu thì mới ép kiểu sang Guid
            var userId = Guid.Parse(userIdString);
            // Tìm xem token này đã có trong DB chưa
            var existingDevice = await _context.UserDevices
                .FirstOrDefaultAsync(d => d.DeviceToken == request.DeviceToken && d.UserId == userId);

            if (existingDevice == null)
            {
                // Chưa có thì tạo mới
                _context.UserDevices.Add(new UserDevice
                {
                    UserId = userId,
                    DeviceToken = request.DeviceToken,
                    LastUpdated = DateTime.UtcNow // 👈 Khớp với file của bạn
                });
            }
            else
            {
                // Có rồi thì cập nhật ngày giờ để biết user vẫn đang online
                existingDevice.LastUpdated = DateTime.UtcNow; 
            }

            await _context.SaveChangesAsync();
            return Ok(new { Message = "Đã lưu Device Token thành công" });
        }

        // ... (Hàm send-test giữ nguyên như tin nhắn trước)
    }

    public class RegisterTokenRequest
    {
        public string DeviceToken { get; set; }
    }
}