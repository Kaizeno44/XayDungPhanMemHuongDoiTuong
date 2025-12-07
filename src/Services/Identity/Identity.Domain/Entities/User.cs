namespace Identity.Domain.Entities
{
    public class User
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public string FullName { get; set; }
        public string Email { get; set; }
        public string PasswordHash { get; set; }
        public bool IsActive { get; set; }

        // --- Thay đổi lớn ở đây ---
        // User này thuộc về Hộ kinh doanh nào?
        public Guid? StoreId { get; set; } 
        public Store? Store { get; set; }
        
        // Cờ đánh dấu: Người này là CHỦ của cái Store kia?
        public bool IsOwner { get; set; } 

        public ICollection<UserRole> UserRoles { get; set; }
    }
}