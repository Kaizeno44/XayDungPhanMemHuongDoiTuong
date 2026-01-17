using Microsoft.AspNetCore.Identity;

namespace Identity.Domain.Entities
{
    // 👇 Kế thừa IdentityUserRole<Guid>
    public class UserRole : IdentityUserRole<Guid>
    {
        // ❌ ĐÃ XÓA: UserId và RoleId (Cha đã có, để lại là bị lỗi ngay)

        // 👇 Chỉ giữ lại Navigation Property để code dễ gọi (u.UserRoles...)
        public virtual User User { get; set; }
        public virtual Role Role { get; set; }
    }
}