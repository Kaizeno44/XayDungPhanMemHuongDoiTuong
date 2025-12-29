import 'dart:typed_data'; // <--- Thêm import này
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models.dart';

class InvoiceGenerator {
  // Đổi tên hàm và kiểu trả về
  static Future<Uint8List> generate({
    required PdfPageFormat format, // Thêm tham số format
    required List<CartItem> items,
    required String customerName,
    required String paymentMethod,
    required double totalAmount,
    required String storeId,
  }) async {
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontItalic = await PdfGoogleFonts.robotoItalic();

    final doc = pw.Document();
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final now = DateTime.now();

    doc.addPage(
      pw.Page(
        pageFormat: format, // Dùng format truyền vào từ giao diện xem trước
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          italic: fontItalic,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- HEADER ---
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'HÓA ĐƠN BÁN LẺ',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
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
              pw.SizedBox(height: 20),
              pw.Divider(),

              // --- THÔNG TIN ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Khách hàng: $customerName'),
                      pw.Text(
                        'Hình thức TT: ${paymentMethod == "Cash" ? "Tiền mặt" : "Ghi nợ"}',
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Ngày: ${dateFormat.format(now)}'),
                      pw.Text(
                        'Mã đơn: #${now.millisecondsSinceEpoch.toString().substring(8)}',
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 15),

              // --- BẢNG SẢN PHẨM ---
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(
                  color: PdfColors.grey400,
                  width: 0.5,
                ),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.black,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                headers: [
                  'STT',
                  'Tên sản phẩm',
                  'ĐVT',
                  'SL',
                  'Đơn giá',
                  'Thành tiền',
                ],
                columnWidths: {
                  0: const pw.FixedColumnWidth(30),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FixedColumnWidth(50),
                  3: const pw.FixedColumnWidth(40),
                  4: const pw.FixedColumnWidth(80),
                  5: const pw.FixedColumnWidth(90),
                },
                data: List<List<dynamic>>.generate(items.length, (index) {
                  final item = items[index];
                  return [
                    (index + 1).toString(),
                    item.productName,
                    item.unitName,
                    item.quantity,
                    currencyFormat.format(item.price),
                    currencyFormat.format(item.total),
                  ];
                }),
              ),
              pw.SizedBox(height: 10),

              // --- TỔNG TIỀN ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Tổng thanh toán: ',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  pw.Text(
                    currencyFormat.format(totalAmount),
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 16,
                      color: PdfColors.red,
                    ),
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Center(
                child: pw.Text(
                  'Cảm ơn và hẹn gặp lại!',
                  style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
                ),
              ),
            ],
          );
        },
      ),
    );

    // TRẢ VỀ DỮ LIỆU FILE (Thay vì in luôn)
    return doc.save();
  }

  static Future<void> generateAndPrint({
    required List<CartItem> items,
    required String customerName,
    required String paymentMethod,
    required double totalAmount,
    required String storeId,
  }) async {}
}
