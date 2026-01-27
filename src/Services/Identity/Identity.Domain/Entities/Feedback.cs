using System;

namespace Identity.Domain.Entities
{
    public class Feedback
    {
        public Guid Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public bool IsResolved { get; set; } = false;

        // Thông tin người gửi
        public Guid UserId { get; set; }
        public User? User { get; set; }

        public Guid? StoreId { get; set; }
        public Store? Store { get; set; }
    }
}
