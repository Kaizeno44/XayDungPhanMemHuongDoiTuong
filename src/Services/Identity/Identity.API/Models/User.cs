using System.ComponentModel.DataAnnotations;

namespace Identity.API.Models
{
    public class User
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public string Email { get; set; } = string.Empty;

        [Required]
        public string Password { get; set; } = string.Empty; // Lưu ý: Thực tế sẽ lưu Hash, demo lưu text cho dễ hiểu

        public string FullName { get; set; } = string.Empty;
        
        public string Role { get; set; } = "User"; // User hoặc Admin
    }
}