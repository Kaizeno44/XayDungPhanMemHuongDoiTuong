using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BizFlow.ProductAPI.DbModels
{
    [Table("Categories")]
    public class Category
    {
        [Key]
        public int Id { get; set; }

        [Required, MaxLength(50)]
        public string Code { get; set; } = string.Empty; // Mã nhóm (VD: CAT, DA)

        [Required, MaxLength(100)]
        public string Name { get; set; } = string.Empty;
    }
}