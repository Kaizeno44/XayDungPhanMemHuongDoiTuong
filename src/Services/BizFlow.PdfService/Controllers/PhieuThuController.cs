using BizFlow.PdfService.Services;
using Microsoft.AspNetCore.Mvc;

namespace BizFlow.PdfService.Controllers
{
    [ApiController]
    [Route("api/Pdf")]
    public class PhieuThuController : ControllerBase
    {
        private readonly IPhieuThuPdfService _pdfService;

        public PhieuThuController(IPhieuThuPdfService pdfService)
        {
            _pdfService = pdfService;
        }

        [HttpPost("generate")]
        public IActionResult GeneratePhieuThu([FromBody] PhieuThuData data)
        {
            try
            {
                var pdfBytes = _pdfService.GeneratePhieuThuPdf(data);
                return File(pdfBytes, "application/pdf", $"PhieuThu_{DateTime.Now:yyyyMMddHHmmss}.pdf");
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = "Lỗi khi tạo PDF", error = ex.Message });
            }
        }
    }
}
