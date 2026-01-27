using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Identity.API.Data;
using Identity.Domain.Entities;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;

namespace Identity.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class FeedbackController : ControllerBase
    {
        private readonly AppDbContext _context;

        public FeedbackController(AppDbContext context)
        {
            _context = context;
        }

        // 1. POST: api/feedback - Gửi phản hồi (Dành cho Chủ hộ/Nhân viên)
        [HttpPost]
        public async Task<IActionResult> SendFeedback([FromBody] FeedbackRequest request)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim)) return Unauthorized();

            var storeIdClaim = User.FindFirst("StoreId")?.Value;
            
            var feedback = new Feedback
            {
                Id = Guid.NewGuid(),
                Title = request.Title,
                Content = request.Content,
                CreatedAt = DateTime.UtcNow,
                IsResolved = false,
                UserId = Guid.Parse(userIdClaim),
                StoreId = !string.IsNullOrEmpty(storeIdClaim) ? Guid.Parse(storeIdClaim) : null
            };

            _context.Feedbacks.Add(feedback);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Gửi phản hồi thành công!" });
        }

        // 2. GET: api/feedback - Lấy danh sách phản hồi (Dành cho SuperAdmin)
        [HttpGet]
        public async Task<IActionResult> GetAllFeedback()
        {
            var feedbacks = await _context.Feedbacks
                .Include(f => f.User)
                .Include(f => f.Store)
                .OrderByDescending(f => f.CreatedAt)
                .Select(f => new
                {
                    f.Id,
                    f.Title,
                    f.Content,
                    f.CreatedAt,
                    f.IsResolved,
                    UserName = f.User != null ? f.User.FullName : "N/A",
                    UserEmail = f.User != null ? f.User.Email : "N/A",
                    StoreName = f.Store != null ? f.Store.StoreName : "Hệ thống"
                })
                .ToListAsync();

            return Ok(feedbacks);
        }

        // 3. PUT: api/feedback/{id}/resolve - Đánh dấu đã xử lý
        [HttpPut("{id}/resolve")]
        public async Task<IActionResult> ResolveFeedback(Guid id)
        {
            var feedback = await _context.Feedbacks.FindAsync(id);
            if (feedback == null) return NotFound();

            feedback.IsResolved = true;
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã đánh dấu xử lý phản hồi." });
        }
    }

    public class FeedbackRequest
    {
        public string Title { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
    }
}
