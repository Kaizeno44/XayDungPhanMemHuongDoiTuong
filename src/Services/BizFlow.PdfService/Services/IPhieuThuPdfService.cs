using System;

namespace BizFlow.PdfService.Services
{
    public interface IPhieuThuPdfService
    {
        byte[] GeneratePhieuThuPdf(PhieuThuData data);
    }

    public class PhieuThuData
    {
        public string BusinessName { get; set; } = "..........................";
        public string BusinessAddress { get; set; } = "....................................................";
        public DateTime ReceiptDate { get; set; } = DateTime.Now;
        public string BookNumber { get; set; } = "................";
        public string ReceiptNumber { get; set; } = "..........................";
        public string PayerName { get; set; } = ".......................................................................................................";
        public string PayerAddress { get; set; } = "..............................................................................................................................................";
        public string ReasonForPayment { get; set; } = "............................................................................................................................................";
        public decimal Amount { get; set; } = 0;
        public string AmountInWords { get; set; } = "................................................................................";
        public string AttachedDocuments { get; set; } = "...................................................................";
        public string OriginalDocuments { get; set; } = "..........................................";
    }
}
