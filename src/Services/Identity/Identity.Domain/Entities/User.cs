using Microsoft.AspNetCore.Identity;

namespace Identity.Domain.Entities
{
    // 👇 Kế thừa IdentityUser<Guid>
    public class User : IdentityUser<Guid>
    {
        // ❌ ĐÃ XÓA: Id, Email, PasswordHash (Cha đã có)

        public string FullName { get; set; }
        public bool IsActive { get; set; } // Giữ lại để dùng cho logic khóa mềm
        public bool IsOwner { get; set; }

        public Guid? StoreId { get; set; }
        public Store? Store { get; set; }

        public ICollection<UserRole> UserRoles { get; set; }
    }
}