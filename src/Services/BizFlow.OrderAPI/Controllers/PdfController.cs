using BizFlow.OrderAPI.Services.Pdf;
using Microsoft.AspNetCore.Mvc;
using System;

namespace BizFlow.OrderAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PdfController : ControllerBase
    {
        [HttpPost("generate-phieuthu")]
        public IActionResult GeneratePhieuThuPdf([FromBody] PhieuThuData data)
        {
            if (data == null)
            {
                return BadRequest("Invalid data provided for Phieu Thu.");
            }

            try
            {
                byte[] pdfBytes = PhieuThuPdfService.GeneratePhieuThuPdf(data);
                return File(pdfBytes, "application/pdf", $"PhieuThu_{data.ReceiptNumber}.pdf");
            }
            catch (Exception ex)
            {
                // Log the exception (e.g., using ILogger)
                Console.WriteLine($"Error generating Phieu Thu PDF: {ex.Message}");
                return StatusCode(500, "An error occurred while generating the PDF.");
            }
        }
    }
}
