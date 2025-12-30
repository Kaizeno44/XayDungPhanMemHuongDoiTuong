using BizFlow.OrderAPI.DTOs;
using System.Net.Http;
using System.Net.Http.Json;

namespace BizFlow.OrderAPI.Services
{
    public class ProductServiceClient
    {
        private readonly HttpClient _httpClient;

        public ProductServiceClient(HttpClient httpClient)
        {
            _httpClient = httpClient;
        }

        // ✅ CHECK STOCK (BATCH)
        public async Task<List<CheckStockResult>> CheckStockAsync(
            List<CheckStockRequest> items)
        {
            var response = await _httpClient.PostAsJsonAsync(
                "/api/Products/check-stock",
                items
            );

            response.EnsureSuccessStatusCode();

#pragma warning disable CS8603 // Possible null reference return.
            return await response.Content
                .ReadFromJsonAsync<List<CheckStockResult>>();
#pragma warning restore CS8603 // Possible null reference return.
        }

        // ✅ TRỪ KHO (ĐÚNG API PRODUCT)
        public async Task DeductStockAsync(
            int productId, int unitId, int quantity)
        {
            var payload = new
            {
                productId = productId,
                unitId = unitId,
                quantityChange = -quantity // ❗ trừ kho
            };

            var response = await _httpClient.PutAsJsonAsync(
                "/api/Products/stock?mode=auto",
                payload
            );

            if (!response.IsSuccessStatusCode)
            {
                throw new ApplicationException(
                    $"Không thể trừ kho cho sản phẩm {productId}.");
            }
        }
    }
}
