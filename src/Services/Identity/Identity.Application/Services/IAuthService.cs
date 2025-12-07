using Identity.Application.DTOs;

namespace Identity.Application.Services
{
    public interface IAuthService
    {
        Task<string> RegisterAsync(RegisterRequest request); // Trả về thông báo thành công
        Task<string> LoginAsync(LoginRequest request);       // Trả về JWT Token
    }
}