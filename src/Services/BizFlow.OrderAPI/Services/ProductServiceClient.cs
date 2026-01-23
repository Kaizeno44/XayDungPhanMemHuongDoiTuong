using BizFlow.OrderAPI.DTOs;
using Microsoft.Extensions.Logging;
using System.Net.Http.Json;

namespace BizFlow.OrderAPI.Services
{
    public class ProductServiceClient
    {
        private readonly HttpClient _httpClient;
        private readonly ILogger<ProductServiceClient> _logger;

        public ProductServiceClient(HttpClient httpClient, ILogger<ProductServiceClient> logger)
        {
            _httpClient = httpClient;
            _logger = logger;
        }

        // ✅ [MỚI] Lấy thông tin sản phẩm (để lấy Tên SP cho Dashboard)
        // Nếu bạn chưa có DTO ProductDto, hãy tạo nó trong folder DTOs nhé
        public async Task<ProductDto?> GetProductByIdAsync(int id)
        {
            try
            {
                // Gọi API lấy chi tiết sản phẩm
                // Route này phải khớp với bên ProductAPI (ví dụ: GET /api/Products/{id})
                var response = await _httpClient.GetAsync($"/api/Products/{id}");

                if (response.IsSuccessStatusCode)
                {
                    return await response.Content.ReadFromJsonAsync<ProductDto>();
                }
                
                _logger.LogWarning("⚠️ [GetProduct] Không tìm thấy SP {Id} hoặc lỗi {Code}", id, response.StatusCode);
                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "🔴 [GetProduct] Lỗi kết nối khi lấy SP {Id}", id);
                return null; // Trả về null để Dashboard không bị crash, chỉ hiển thị thiếu tên
            }
        }

        // ✅ CHECK STOCK (BATCH)
        public async Task<List<CheckStockResult>> CheckStockAsync(List<CheckStockRequest> items)
        {
            try
            {
                _logger.LogInformation("🔵 [CheckStock] Đang kiểm tra tồn kho cho {Count} sản phẩm...", items.Count);

                var payload = new { Requests = items };

                var response = await _httpClient.PostAsJsonAsync("/api/Products/check-stock", payload);

                if (!response.IsSuccessStatusCode)
                {
                    var errorContent = await response.Content.ReadAsStringAsync();
                    _logger.LogError("🔴 [CheckStock] Lỗi từ ProductAPI ({Code}): {Error}", response.StatusCode, errorContent);
                    throw new HttpRequestException($"Lỗi ProductAPI: {errorContent}");
                }

                var result = await response.Content.ReadFromJsonAsync<List<CheckStockResult>>();
                return result ?? new List<CheckStockResult>();
            }
            catch (Exception ex) when (ex is not HttpRequestException)
            {
                _logger.LogError(ex, "🔴 [CheckStock] Lỗi kết nối hoặc parse JSON.");
                throw;
            }
        }

        // ✅ TRỪ KHO
        public async Task DeductStockAsync(int productId, int unitId, int quantity)
        {
            var payload = new
            {
                productId = productId,
                unitId = unitId,
                quantityChange = -quantity
            };

            try
            {
                _logger.LogInformation("🔵 [DeductStock] Đang trừ kho SP {ProductId}, Unit {UnitId}, SL {Qty}", productId, unitId, quantity);

                var response = await _httpClient.PutAsJsonAsync("/api/Products/stock?mode=auto", payload);

                if (!response.IsSuccessStatusCode)
                {
                    var errorContent = await response.Content.ReadAsStringAsync();
                    _logger.LogError("🔴 [DeductStock] Thất bại ({Code}): {Error}", response.StatusCode, errorContent);
                    throw new InvalidOperationException($"Không thể trừ kho SP {productId}: {errorContent}");
                }

                _logger.LogInformation("🟢 [DeductStock] Trừ kho thành công.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "🔴 [DeductStock] Exception khi gọi API.");
                throw;
            }
        }
    }
}