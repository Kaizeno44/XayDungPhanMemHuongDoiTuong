using BizFlow.OrderAPI.Data;
using BizFlow.OrderAPI.DTOs;
using BizFlow.OrderAPI.DbModels;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BizFlow.OrderAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class CustomersController : ControllerBase
    {
        private readonly OrderDbContext _context;

        public CustomersController(OrderDbContext context)
        {
            _context = context;
        }

        // ==========================================
        // 1. GET: api/Customers (Lấy danh sách)
        // 👉 API NÀY ĐỂ SỬA LỖI 404 BÊN FLUTTER
        // ==========================================
        [HttpGet]
        public async Task<ActionResult<IEnumerable<CustomerDto>>> GetCustomers()
        {
            var customers = await _context.Customers
                .OrderBy(c => c.FullName) // Sắp xếp tên A-Z cho đẹp
                .Select(c => new CustomerDto // Sử dụng CustomerDto rõ ràng
                {
                    Id = c.Id,
                    FullName = c.FullName,
                    PhoneNumber = c.PhoneNumber,
                    Address = c.Address,
                    CurrentDebt = c.CurrentDebt,
                    StoreId = c.StoreId
                })
                .ToListAsync();

            return Ok(customers);
        }

        // ==========================================
        // 2. POST: api/Customers (Tạo khách hàng mới)
        // 👉 Dùng cái này tạo khách cho nhanh, khỏi vào Adminer
        // ==========================================
        [HttpPost]
        public async Task<IActionResult> CreateCustomer([FromBody] Customer customer)
        {
            if (customer.Id == Guid.Empty)
                customer.Id = Guid.NewGuid(); // Tự tạo ID nếu thiếu

            if (string.IsNullOrEmpty(customer.FullName))
                return BadRequest("Tên khách hàng không được để trống");

            // Mặc định nợ = 0 khi mới tạo
            customer.CurrentDebt = 0;

            _context.Customers.Add(customer);
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Tạo khách hàng thành công!", CustomerId = customer.Id });
        }

        // ==========================================
        // 3. GET: api/customers/{id}/history
        // ==========================================
        [HttpGet("{id}/history")]
        public async Task<IActionResult> GetHistory(Guid id)
        {
            // Kiểm tra khách có tồn tại không trước
            var customer = await _context.Customers.FindAsync(id);
            if (customer == null)
            {
                return NotFound(new { Message = "Khách hàng không tồn tại." });
            }

            // Tính tổng nợ thực tế từ Log (để đối chiếu)
            var totalDebt = await _context.DebtLogs
                .Where(d => d.CustomerId == id)
                .SumAsync(d => d.Amount);

            // Lấy danh sách đơn hàng
            var orders = await _context.Orders
                .Where(o => o.CustomerId == id)
                .OrderByDescending(o => o.OrderDate)
                .Select(o => new OrderHistoryItemDto
                {
                    Id = o.Id,
                    OrderCode = o.OrderCode,
                    TotalAmount = o.TotalAmount,
                    Status = o.Status,
                    OrderDate = o.OrderDate,
                    PaymentMethod = o.PaymentMethod
                })
                .ToListAsync();

            var response = new CustomerHistoryResponse
            {
                CustomerId = id,
                CurrentDebt = customer.CurrentDebt, // Lấy CurrentDebt từ bảng Customer cho chuẩn xác
                OrderCount = orders.Count,
                Orders = orders
            };

            return Ok(response);
        }

        // ==========================================
        // 4. POST: api/customers/pay-debt (Trả nợ)
        // ==========================================
        [HttpPost("pay-debt")]
        public async Task<IActionResult> PayDebt([FromBody] PayDebtRequest request)
        {
            if (request.Amount <= 0)
                return BadRequest(new { Message = "Số tiền trả phải lớn hơn 0." });

            // 1. Kiểm tra khách hàng
            var customer = await _context.Customers.FindAsync(request.CustomerId);
            if (customer == null)
                return NotFound(new { Message = "Khách hàng không tồn tại." });

            // 2. Ghi log trả nợ (Amount ÂM để trừ nợ)
            var debtLog = new DebtLog
            {
                Id = Guid.NewGuid(), // Tạo ID mới cho log
                CustomerId = request.CustomerId,
// Kiểm tra nếu StoreId gửi lên là rỗng (Guid.Empty) thì lấy StoreId của khách hàng
StoreId = (request.StoreId == Guid.Empty) ? customer.StoreId : request.StoreId,                Amount = -request.Amount,         // 👈 DẤU TRỪ QUAN TRỌNG
                Action = "Repayment",
                Reason = "Khách thanh toán nợ",
                CreatedAt = DateTime.UtcNow
            };

            _context.DebtLogs.Add(debtLog);

            // 3. Cập nhật nhanh CurrentDebt trong Customer
            // Ép kiểu sang decimal để tính toán chính xác với tiền tệ
            decimal paymentAmount = (decimal)request.Amount;
            customer.CurrentDebt -= paymentAmount;

            // 4. Chống nợ âm hoặc sai số nhỏ
            // Nếu nợ còn lại nhỏ hơn 10đ (coi như bằng 0 cho VNĐ) hoặc bị âm do làm tròn
            if (customer.CurrentDebt < 10)
            {
                customer.CurrentDebt = 0;
            }

            await _context.SaveChangesAsync();

            return Ok(new
            {
                Message = "Thanh toán nợ thành công!",
                NewDebt = customer.CurrentDebt
            });
        }
    }
}
