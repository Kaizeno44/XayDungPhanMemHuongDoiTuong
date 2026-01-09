using Microsoft.AspNetCore.Identity;

namespace Identity.Domain.Entities
{
    // 👇 Kế thừa IdentityRole<Guid>
    public class Role : IdentityRole<Guid>
    {
        // ❌ ĐÃ XÓA: Id, Name (Cha đã có)

        public string? Description { get; set; }
        public ICollection<UserRole> UserRoles { get; set; }
    }
}