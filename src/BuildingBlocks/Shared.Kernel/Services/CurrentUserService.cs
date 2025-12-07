using Microsoft.AspNetCore.Http;
using System.Security.Claims;

namespace Shared.Kernel.Services
{
    public interface ICurrentUserService
    {
        string? UserId { get; }
        string? StoreId { get; } // Quan trọng nhất
        bool IsOwner { get; }
    }

    public class CurrentUserService : ICurrentUserService
    {
        private readonly IHttpContextAccessor _httpContextAccessor;

        public CurrentUserService(IHttpContextAccessor httpContextAccessor)
        {
            _httpContextAccessor = httpContextAccessor;
        }

        public string? UserId => _httpContextAccessor.HttpContext?.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        
        // Lấy StoreId từ Token (Claim tên là "StoreId" mà bạn đã code ở tuần 2)
        public string? StoreId => _httpContextAccessor.HttpContext?.User?.FindFirst("StoreId")?.Value;
        
        public bool IsOwner => _httpContextAccessor.HttpContext?.User?.FindFirst("IsOwner")?.Value == "True";
    }
}