using Microsoft.Extensions.Caching.Distributed;

namespace Identity.API.Middlewares
{
    public class TokenBlacklistMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly IDistributedCache _cache;

        public TokenBlacklistMiddleware(RequestDelegate next, IDistributedCache cache)
        {
            _next = next;
            _cache = cache;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            // 1. Lấy Token từ Header
            var token = context.Request.Headers["Authorization"].ToString().Replace("Bearer ", "");

            if (!string.IsNullOrEmpty(token))
            {
                // 2. Kiểm tra trong Redis
                var blacklisted = await _cache.GetStringAsync($"blacklist_{token}");
                if (blacklisted != null)
                {
                    context.Response.StatusCode = 401; // Unauthorized
                    await context.Response.WriteAsync("Token has been revoked. Please login again.");
                    return;
                }
            }

            await _next(context);
        }
    }

    // Extension method để đăng ký dễ hơn
    public static class TokenBlacklistMiddlewareExtensions
    {
        public static IApplicationBuilder UseTokenBlacklist(this IApplicationBuilder builder)
        {
            return builder.UseMiddleware<TokenBlacklistMiddleware>();
        }
    }
}
