using BizFlow.OrderAPI.Data;
using BizFlow.OrderAPI.DbModels;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BizFlow.OrderAPI.Controllers
{
    [Route("api/customers")]
    [ApiController]
    public class CustomersController : ControllerBase
    {
        private readonly OrderDbContext _context;

        public CustomersController(OrderDbContext context)
        {
            _context = context;
        }

        // API: Thêm khách hàng mới
        [HttpPost]
        public async Task<IActionResult> CreateCustomer([FromBody] CreateCustomerRequest request)
        {
            // 1. Giả lập mã cửa hàng (Cho giống với bên OrdersController)
            var currentStoreId = Guid.Parse("11111111-1111-1111-1111-111111111111");

            // 2. Tạo đối tượng khách hàng
            var newCustomer = new Customer
            {
                Id = Guid.NewGuid(),
                StoreId = currentStoreId, // 👈 Quan trọng: Đánh dấu khách này thuộc cửa hàng của bạn
                FullName = request.FullName,
                PhoneNumber = request.PhoneNumber,
                Address = request.Address,
                CurrentDebt = 0
            };

            _context.Customers.Add(newCustomer);
            await _context.SaveChangesAsync();

            return Ok(new { Success = true, Message = "Thêm khách hàng thành công!", CustomerId = newCustomer.Id });
        }
    }

    // Class hứng dữ liệu gửi lên (DTO)
    public class CreateCustomerRequest
    {
        public string FullName { get; set; } = "";
        public string PhoneNumber { get; set; } = "";
        public string Address { get; set; } = "";
    }
}