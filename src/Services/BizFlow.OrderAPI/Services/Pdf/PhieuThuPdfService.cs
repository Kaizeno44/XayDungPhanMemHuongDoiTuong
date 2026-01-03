using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;
using System;

namespace BizFlow.OrderAPI.Services.Pdf
{
    public static class PhieuThuPdfService
    {
        public static byte[] GeneratePhieuThuPdf(PhieuThuData data)
        {
            // Cấu hình License (Bắt buộc cho phiên bản mới của QuestPDF)
            QuestPDF.Settings.License = LicenseType.Community;

            return Document.Create(container =>
            {
                container.Page(page =>
                {
                    page.Size(PageSizes.A4);
                    page.Margin(1, Unit.Centimetre);
                    page.PageColor(Colors.White);
                    
                    // Thiết lập font chữ mặc định (Nên dùng Times New Roman cho văn bản kế toán)
                    page.DefaultTextStyle(x => x.FontSize(11).FontFamily(Fonts.TimesNewRoman));

                    page.Content().Column(col =>
                    {
                        // --- PHẦN TIÊU ĐỀ (HEADER) ---
                        col.Item().Row(row =>
                        {
                            row.RelativeItem(1.5f).Column(c =>
                            {
                                c.Item().Text(t => {
                                    t.Span("HỘ, CÁ NHÂN KINH DOANH: ").Bold();
                                    t.Span(string.IsNullOrEmpty(data.BusinessName) ? ".........." : data.BusinessName).Bold();
                                });
                                c.Item().Text(t => {
                                    t.Span("Địa chỉ: ").Bold();
                                    t.Span(string.IsNullOrEmpty(data.BusinessAddress) ? "...................................................." : data.BusinessAddress).Bold();
                                });
                            });

                            row.RelativeItem(1).Column(c =>
                            {
                                c.Item().AlignCenter().Text("Mẫu số 01 – TT").Bold();
                                c.Item().AlignCenter().Text("(Ban hành kèm theo Thông tư số 88/2021/TT-BTC").Italic().FontSize(9);
                                c.Item().AlignCenter().Text("ngày 11 tháng 10 năm 2021 của Bộ trưởng Bộ Tài chính)").Italic().FontSize(9);
                            });
                        });

                        // --- TÊN CHỨNG TỪ ---
                        col.Item().PaddingTop(10).AlignCenter().Column(c =>
                        {
                            c.Item().Text("PHIẾU THU").FontSize(16).SemiBold();
                            c.Item().Text("Ngày ...... tháng ...... năm ......").Italic();
                        });

                        // --- SỐ QUYỂN / SỐ PHIẾU ---
                        col.Item().AlignRight().PaddingRight(50).Column(c =>
                        {
                            c.Item().Text("Quyển số:................");
                            c.Item().Text("Số:..........................");
                        });

                        // --- PHẦN THÔNG TIN CHI TIẾT ---
                        col.Item().PaddingTop(15).Column(c =>
                        {
                            const float lineSpacing = 8; // Khoảng cách dòng theo yêu cầu

                            c.Item().PaddingBottom(lineSpacing).Text(t => { 
                                t.Span("Họ và tên người nộp tiền: "); 
                                t.Span(string.IsNullOrEmpty(data.PayerName) ? "......................................................................................................." : data.PayerName); 
                            });
                            
                            c.Item().PaddingBottom(lineSpacing).Text(t => { 
                                t.Span("Địa chỉ: "); 
                                t.Span(string.IsNullOrEmpty(data.PayerAddress) ? ".............................................................................................................................................." : data.PayerAddress); 
                            });
                            
                            c.Item().PaddingBottom(lineSpacing).Text(t => { 
                                t.Span("Lý do nộp: "); 
                                t.Span(string.IsNullOrEmpty(data.ReasonForPayment) ? "............................................................................................................................................" : data.ReasonForPayment); 
                            });
                            
                            c.Item().PaddingBottom(lineSpacing).Text(t => { 
                                t.Span("Số tiền: "); 
                                t.Span(data.Amount == 0 ? "................................." : $"{data.Amount:N0} đ").Bold(); 
                                t.Span(" (Viết bằng chữ): ");
                                t.Span(string.IsNullOrEmpty(data.AmountInWords) || data.AmountInWords.Contains("Số tiền tương ứng") ? "................................................................................." : data.AmountInWords);
                            });
                            
                            c.Item().PaddingBottom(15).Text(t => { 
                                t.Span("Kèm theo: "); 
                                t.Span(string.IsNullOrEmpty(data.AttachedDocuments) ? "..................................................................." : data.AttachedDocuments); 
                                t.Span(" Chứng từ gốc: "); 
                                t.Span(string.IsNullOrEmpty(data.OriginalDocuments) ? ".........................................." : data.OriginalDocuments); 
                            });
                        });

                        // --- PHẦN CHỮ KÝ ---
                        col.Item().AlignRight().PaddingRight(20).Text("Ngày ...... tháng ...... năm ......").Italic();

                        col.Item().PaddingTop(10).Row(row =>
                        {
                            // Chia làm 4 cột bằng nhau cho các chức danh
                            row.RelativeItem().AlignCenter().Column(c => {
                                c.Item().Text("NGƯỜI ĐẠI DIỆN").Bold();
                                c.Item().Text("HỘ KINH DOANH").Bold();
                                c.Item().Text("(Ký, họ tên, đóng dấu)").Italic().FontSize(9);
                            });
                            row.RelativeItem().AlignCenter().Column(c => {
                                c.Item().Text("NGƯỜI LẬP BIỂU").Bold();
                                c.Item().Text("(Ký, họ tên)").Italic().FontSize(9);
                            });
                            row.RelativeItem().AlignCenter().Column(c => {
                                c.Item().Text("NGƯỜI NỘP TIỀN").Bold();
                                c.Item().Text("(Ký, họ tên)").Italic().FontSize(9);
                            });
                            row.RelativeItem().AlignCenter().Column(c => {
                                c.Item().Text("THỦ QUỸ").Bold();
                                c.Item().Text("(Ký, họ tên)").Italic().FontSize(9);
                            });
                        });

                        // --- DÒNG XÁC NHẬN CUỐI CÙNG ---
                        col.Item().PaddingTop(50).Text(t => 
                        {
                            t.Span("Đã nhận đủ số tiền (viết bằng chữ): ").Bold();
                            t.Span(string.IsNullOrEmpty(data.AmountInWords) || data.AmountInWords.Contains("Số tiền tương ứng") ? "........................................................................................................." : data.AmountInWords);
                        });
                    });
                });
            }).GeneratePdf();
        }
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
