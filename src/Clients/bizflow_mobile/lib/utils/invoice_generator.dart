import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models.dart';

class InvoiceGenerator {
  // 1. ĐỊNH NGHĨA MÀU SẮC CHỦ ĐẠO (Màu Cam Orange[800] giống App)
  // Mã Hex của Colors.orange[800] là #EF6C00
  static const PdfColor _primaryColor = PdfColor.fromInt(0xFFEF6C00);
  static const PdfColor _textColor = PdfColors.black;
  static const PdfColor _totalColor = PdfColors.red;

  static Future<Uint8List> generate({
    required PdfPageFormat format,
    required List<CartItem> items,
    required String customerName,
    required String paymentMethod,
    required double totalAmount,
    required String storeId,
  }) async {
    // Tải font chữ hỗ trợ tiếng Việt
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontItalic = await PdfGoogleFonts.robotoItalic();

    final doc = pw.Document();
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final now = DateTime.now();

    doc.addPage(
      pw.Page(
        pageFormat: format,
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          italic: fontItalic,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- 1. HEADER (TIÊU ĐỀ) ---
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'HÓA ĐƠN BÁN LẺ',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: _primaryColor, // Đổi màu tiêu đề thành màu Cam
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Cửa hàng: BizFlow - Chi nhánh $storeId',
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 15),
              pw.Divider(color: _primaryColor, thickness: 1), // Đường kẻ màu Cam
              pw.SizedBox(height: 15),

              // --- 2. THÔNG TIN KHÁCH HÀNG & ĐƠN HÀNG ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Khách hàng:', customerName),
                      pw.SizedBox(height: 4),
                      _buildInfoRow(
                        'Hình thức TT:',
paymentMethod == "Cash" ? "Tiền mặt" : "Ghi nợ",
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _buildInfoRow('Ngày:', dateFormat.format(now)),
                      pw.SizedBox(height: 4),
                      _buildInfoRow(
                        'Mã đơn:',
                        '#${now.millisecondsSinceEpoch.toString().substring(8)}',
                        isBold: true,
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // --- 3. BẢNG SẢN PHẨM ---
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 10,
                ),
                // Đổi nền Header bảng thành màu Cam
                headerDecoration: const pw.BoxDecoration(
                  color: _primaryColor, 
                ),
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellAlignment: pw.Alignment.centerLeft,
                headers: ['STT', 'Tên sản phẩm', 'ĐVT', 'SL', 'Đơn giá', 'Thành tiền'],
                columnWidths: {
                  0: const pw.FixedColumnWidth(30), // STT
                  1: const pw.FlexColumnWidth(3),   // Tên
                  2: const pw.FixedColumnWidth(40), // ĐVT
                  3: const pw.FixedColumnWidth(30), // SL
                  4: const pw.FixedColumnWidth(70), // Đơn giá
                  5: const pw.FixedColumnWidth(80), // Thành tiền
                },
                data: List<List<dynamic>>.generate(items.length, (index) {
                  final item = items[index];
                  return [
                    (index + 1).toString(),
                    item.productName,
                    item.unitName,
                    item.quantity.toString(), // Sửa: Chuyển int/double sang String nếu cần
                    currencyFormat.format(item.price),
                    currencyFormat.format(item.total),
                  ];
                }),
              ),
              pw.SizedBox(height: 15),

              // --- 4. TỔNG TIỀN ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Tổng thanh toán',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        currencyFormat.format(totalAmount),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 20,
                          color: _totalColor, // Màu đỏ cho số tiền
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              pw.Spacer(),
              
              // --- 5. FOOTER ---
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Cảm ơn quý khách và hẹn gặp lại!',
                  style: pw.TextStyle(
                    fontStyle: pw.FontStyle.italic,
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  // Hàm phụ trợ để tạo dòng thông tin nhanh gọn
  static pw.Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$label ',
            style: pw.TextStyle(
              color: PdfColors.grey700,
              fontSize: 10,
            ),
          ),
          pw.TextSpan(
            text: value,
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: PdfColors.black,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
