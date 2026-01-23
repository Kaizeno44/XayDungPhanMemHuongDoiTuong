import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';

part 'stock_import.g.dart';

@JsonSerializable()
class StockImport {
  final int id;
  final String productName;
  final String unitName;
  final double quantity;
  final double unitCost; // Giá vốn đơn vị (Backend gửi CostPrice)
  final String supplierName;
  final DateTime createdAt; // Ngày nhập (Backend gửi ImportDate)
  final String? note;

  StockImport({
    required this.id,
    required this.productName,
    required this.unitName,
    required this.quantity,
    required this.unitCost,
    required this.supplierName,
    required this.createdAt,
    this.note,
  });

  // --- 1. GETTER TÍNH TOÁN ---

  // Tổng tiền = Số lượng * Giá vốn
  double get totalCost => quantity * unitCost;

  // --- 2. FACTORY PARSE JSON (AN TOÀN) ---
  factory StockImport.fromJson(Map<String, dynamic> json) {
    return StockImport(
      id: json['id'] ?? 0,

      // Xử lý chuỗi (Backend trả về camelCase)
      productName: json['productName'] ?? 'Sản phẩm lỗi',
      unitName: json['unitName'] ?? 'N/A',
      supplierName: json['supplierName'] ?? 'Kho tổng',
      note: json['note'],

      // Xử lý số (Backend trả về số hoặc null)
      quantity: (json['quantity'] ?? 0).toDouble(),
      unitCost: (json['costPrice'] ?? 0)
          .toDouble(), // Map từ 'costPrice' của Backend
      // Xử lý ngày tháng
      createdAt: json['importDate'] != null
          ? DateTime.parse(json['importDate'])
                .toLocal() // Chuyển về giờ địa phương
          : DateTime.now(),
    );
  }

  // --- 3. HELPER FORMAT HIỂN THỊ ---

  // Format giá nhập: 1.250.000 ₫
  String get formattedUnitCost {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return format.format(unitCost);
  }

  // Format tổng tiền: 5.000.000 ₫
  String get formattedTotal {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return format.format(totalCost);
  }

  // Format số lượng: 10 hoặc 10.5
  String get formattedQuantity {
    // Nếu là số nguyên thì bỏ .0 (VD: 10.0 -> 10)
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }
    return quantity.toString();
  }

  // Format ngày: 23/01/2026 14:30
  String get formattedDate {
    return DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
  }

  // --- 4. COPY WITH ---
  StockImport copyWith({
    int? id,
    String? productName,
    String? unitName,
    double? quantity,
    double? unitCost,
    String? supplierName,
    DateTime? createdAt,
    String? note,
  }) {
    return StockImport(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      unitName: unitName ?? this.unitName,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      supplierName: supplierName ?? this.supplierName,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => _$StockImportToJson(this);
}
