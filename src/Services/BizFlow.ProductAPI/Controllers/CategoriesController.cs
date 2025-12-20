using Microsoft.AspNetCore.Mvc;
using BizFlow.ProductAPI.Data;
using BizFlow.ProductAPI.DbModels;
using BizFlow.ProductAPI.DTOs;

namespace BizFlow.ProductAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class CategoriesController : ControllerBase
    {
        private readonly ProductDbContext _context;

        public CategoriesController(ProductDbContext context)
        {
            _context = context;
        }

        [HttpPost]
        public IActionResult Create([FromBody] CreateCategoryRequest request)
        {
            var category = new Category 
            { 
                Name = request.Name, 
                Code = request.Code 
            };

            _context.Categories.Add(category);
            _context.SaveChanges();

            return Ok(new { Message = "Tạo nhóm hàng thành công", Id = category.Id });
        }

        [HttpGet]
        public IActionResult GetAll()
        {
            return Ok(_context.Categories.ToList());
        }
    }
}