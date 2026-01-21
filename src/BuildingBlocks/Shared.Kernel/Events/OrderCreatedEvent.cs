using System;
using System.Collections.Generic;

namespace Shared.Kernel.Events
{
    public class OrderCreatedEvent
    {
        public Guid OrderId { get; set; }
        public string OrderCode { get; set; } // [MỚI] Thêm mã đơn hàng
        public Guid StoreId { get; set; }
        public decimal TotalAmount { get; set; }
        public DateTime CreatedAt { get; set; }
        
        // [MỚI] Danh sách chi tiết để bên Product biết trừ kho cái gì
        public List<OrderItemEvent> OrderItems { get; set; } = new List<OrderItemEvent>();
    }

    // [MỚI] Class con để chứa thông tin item
    public class OrderItemEvent
    {
        public int ProductId { get; set; }
        public int UnitId { get; set; }
        public double Quantity { get; set; }
    }
}