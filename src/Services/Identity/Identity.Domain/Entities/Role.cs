using System;
using System.Collections.Generic;

namespace Identity.Domain.Entities
{
    public class Role
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public string Name { get; set; } // Ví dụ: "Owner", "Employee", "Administrator"
        public string Description { get; set; }

        public ICollection<UserRole> UserRoles { get; set; }
    }
}