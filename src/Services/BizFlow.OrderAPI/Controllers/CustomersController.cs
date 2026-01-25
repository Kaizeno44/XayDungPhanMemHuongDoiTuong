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
        // ==========================================
        [HttpGet]
        public async Task<ActionResult<IEnumerable<CustomerDto>>> GetCustomers()
        {
            var customers = await _context.Customers
                .OrderBy(c => c.FullName) 
                .Select(c => new CustomerDto
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
        // ==========================================
        [HttpPost]
        public async Task<IActionResult> CreateCustomer([FromBody] Customer customer)
        {
            if (customer.Id == Guid.Empty)
                customer.Id = Guid.NewGuid();

            if (string.IsNullOrEmpty(customer.FullName))
                return BadRequest("Tên khách hàng không được để trống");

            customer.CurrentDebt = 0; // Mặc định nợ = 0

            _context.Customers.Add(customer);
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Tạo khách hàng thành công!", CustomerId = customer.Id });
        }

        // ==========================================
        // 3. GET: api/customers/{id}/history
        // 👉 ĐÃ CẬP NHẬT: Lấy thêm Lịch sử Nợ (DebtLogs)
        // ==========================================
        [HttpGet("{id}/history")]
        public async Task<IActionResult> GetHistory(Guid id)
        {
            // 1. Kiểm tra khách có tồn tại không
            var customer = await _context.Customers.FindAsync(id);
            if (customer == null)
            {
                return NotFound(new { Message = "Khách hàng không tồn tại." });
            }

            // 2. Lấy danh sách Đơn hàng (Tab 1)
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

            // 3. 👇 BỔ SUNG MỚI: Lấy danh sách Lịch sử Nợ (Tab 2)
            var debtLogs = await _context.DebtLogs
                .Where(d => d.CustomerId == id)
                .OrderByDescending(d => d.CreatedAt) // Mới nhất lên đầu
                .Select(d => new DebtLogDto
                {
                    Id = d.Id,
                    CreatedAt = d.CreatedAt,
                    Amount = d.Amount,
                    Action = d.Action,      // "Debit" hoặc "Repayment"/"Credit"
                    Reason = d.Reason,      // "Đơn hàng #..." hoặc "Khách trả nợ"
                    RefOrderId = d.RefOrderId
                })
                .ToListAsync();

            // 4. Đóng gói response hoàn chỉnh
            var response = new CustomerHistoryResponse
            {
                CustomerId = id,
                CurrentDebt = customer.CurrentDebt, // Lấy current debt từ bảng Customer
                OrderCount = orders.Count,
                Orders = orders,       // Dữ liệu cho Tab Đơn Hàng
                DebtHistory = debtLogs // 👈 Dữ liệu cho Tab Lịch sử Nợ
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
                Id = Guid.NewGuid(),
                CustomerId = request.CustomerId,
                // Logic thông minh: Nếu StoreId rỗng thì lấy của khách, ngược lại lấy từ request
                StoreId = (request.StoreId == Guid.Empty) ? customer.StoreId : request.StoreId, 
                Amount = -request.Amount, // 👈 Lưu số âm
                Action = "Repayment",     // Đánh dấu là trả nợ
                Reason = "Khách thanh toán nợ",
                CreatedAt = DateTime.UtcNow
            };

            _context.DebtLogs.Add(debtLog);

            // 3. Cập nhật CurrentDebt trong Customer
            customer.CurrentDebt -= request.Amount;

            // 4. Xử lý làm tròn số (Chống nợ âm nhỏ do sai số)
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

    // Class DTO request nội bộ (nếu chưa có file riêng thì để ở đây hoặc move sang DTOs)
    public class PayDebtRequest
    {
        public Guid CustomerId { get; set; }
        public Guid StoreId { get; set; }
        public decimal Amount { get; set; }
    }
}