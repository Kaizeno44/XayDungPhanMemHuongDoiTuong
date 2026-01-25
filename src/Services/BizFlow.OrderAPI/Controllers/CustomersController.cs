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
        public async Task<ActionResult<IEnumerable<CustomerDto>>> GetCustomers([FromQuery] Guid? storeId)
        {
            var query = _context.Customers.AsQueryable();

            // Lọc theo Store nếu có tham số
            if (storeId.HasValue && storeId != Guid.Empty)
            {
                query = query.Where(c => c.StoreId == storeId);
            }

            var customers = await query
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
            if (string.IsNullOrEmpty(customer.FullName))
                return BadRequest(new { Message = "Tên khách hàng không được để trống" });

            if (customer.Id == Guid.Empty) 
                customer.Id = Guid.NewGuid();
            
            customer.CurrentDebt = 0;
            
            // Gán thời gian tạo (Cần đảm bảo Model Customer đã có trường CreatedAt)
            customer.CreatedAt = DateTime.UtcNow;

            _context.Customers.Add(customer);
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Tạo khách hàng thành công!", CustomerId = customer.Id });
        }

        // ==========================================
        // 3. GET: api/Customers/{id}/history (Lịch sử Đơn hàng)
        // ==========================================
        [HttpGet("{id}/history")]
        public async Task<IActionResult> GetHistory(Guid id)
        {
            var customer = await _context.Customers.FindAsync(id);
            if (customer == null)
                return NotFound(new { Message = "Khách hàng không tồn tại." });

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
                CurrentDebt = customer.CurrentDebt,
                OrderCount = orders.Count,
                Orders = orders
            };

            return Ok(response);
        }

        // ==========================================
        // 4. GET: api/Customers/{id}/debt-logs (Lịch sử Nợ)
        // ==========================================
        [HttpGet("{id}/debt-logs")]
        public async Task<IActionResult> GetDebtLogs(Guid id)
        {
            var logs = await _context.DebtLogs
                .Where(d => d.CustomerId == id)
                .OrderByDescending(d => d.CreatedAt)
                .Select(d => new
                {
                    d.Id,
                    Amount = d.Amount,
                    NewDebt = 0, // TODO: Sau này có cột NewDebtSnapshot thì map vào đây
                    Action = d.Action == "Repayment" ? "Payment" : "Order",
                    Note = d.Reason,
                    Timestamp = d.CreatedAt
                })
                .ToListAsync();

            return Ok(logs);
        }

        // ==========================================
        // 5. POST: api/Customers/pay-debt (Thanh toán nợ)
        // ==========================================
        [HttpPost("pay-debt")]
        public async Task<IActionResult> PayDebt([FromBody] PayDebtRequest request)
        {
            if (request.Amount <= 0)
                return BadRequest(new { Message = "Số tiền trả phải lớn hơn 0." });

            // Bắt đầu Transaction
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var customer = await _context.Customers.FindAsync(request.CustomerId);
                if (customer == null)
                    return NotFound(new { Message = "Khách hàng không tồn tại." });

                // Tính toán nợ mới (ép kiểu an toàn)
                decimal paymentAmount = (decimal)request.Amount;
                customer.CurrentDebt -= paymentAmount;

                // Chống âm nợ
                if (customer.CurrentDebt < 0) customer.CurrentDebt = 0;

                // Tạo log trả nợ
                var debtLog = new DebtLog
                {
                    Id = Guid.NewGuid(),
                    CustomerId = request.CustomerId,
                    StoreId = (request.StoreId == Guid.Empty) ? customer.StoreId : request.StoreId,
                    Amount = -paymentAmount, // Số âm = Trả nợ
                    Action = "Repayment",
                    Reason = !string.IsNullOrEmpty(request.Note) ? request.Note : "Khách thanh toán nợ",
                    CreatedAt = DateTime.UtcNow
                };

                _context.DebtLogs.Add(debtLog);
                
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return Ok(new
                {
                    Message = "Thanh toán nợ thành công!",
                    NewDebt = customer.CurrentDebt,
                    LogId = debtLog.Id
                });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, new { Message = "Lỗi hệ thống: " + ex.Message });
            }
        }
    }
}