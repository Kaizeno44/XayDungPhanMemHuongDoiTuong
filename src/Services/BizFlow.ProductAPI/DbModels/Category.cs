using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BizFlow.ProductAPI.DbModels
{
    [Table("Categories")]
    public class Category
    {
        [Key]
        public int Id { get; set; }

        [Required, MaxLength(100)]
        public string Name { get; set; } = string.Empty; // VD: Vật liệu thô

        [MaxLength(50)]
        public string Code { get; set; } = string.Empty; // VD: VLXD

        public string? Description { get; set; } // 👈 Mới thêm

        public bool IsActive { get; set; } = true; // 👈 Mới thêm (Để ẩn hiện danh mục)
    }
}