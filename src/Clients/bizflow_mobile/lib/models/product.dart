import 'package:json_annotation/json_annotation.dart';
import 'package:intl/intl.dart';

part 'product.g.dart';

// ================= 1. INVENTORY MODEL =================
@JsonSerializable()
class Inventory {
  final int id;
  final int productId;
  final double quantity;
  final String? lastUpdated; // Giữ nguyên string để map JSON

  Inventory({
    required this.id,
    required this.productId,
    required this.quantity,
    this.lastUpdated,
  });

  // Helper: Chuyển đổi sang DateTime để dùng trong UI
  DateTime? get lastUpdatedDate {
    if (lastUpdated == null) return null;
    return DateTime.tryParse(lastUpdated!);
  }

  // CopyWith: Cập nhật dữ liệu (đặc biệt hữu ích cho SignalR)
  Inventory copyWith({
    int? id,
    int? productId,
    double? quantity,
    String? lastUpdated,
  }) {
    return Inventory(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  factory Inventory.fromJson(Map<String, dynamic> json) =>
      _$InventoryFromJson(json);
  Map<String, dynamic> toJson() => _$InventoryToJson(this);
}

// ================= 2. PRODUCT UNIT MODEL =================
@JsonSerializable()
class ProductUnit {
  final int id;

  @JsonKey(defaultValue: 0)
  final int productId;

  final String unitName;
  final double price;

  @JsonKey(defaultValue: 1.0)
  final double conversionValue;

  @JsonKey(defaultValue: false)
  final bool isBaseUnit;

  ProductUnit({
    required this.id,
    this.productId = 0,
    required this.unitName,
    required this.price,
    this.conversionValue = 1.0,
    required this.isBaseUnit,
  });

  factory ProductUnit.fromJson(Map<String, dynamic> json) =>
      _$ProductUnitFromJson(json);
  Map<String, dynamic> toJson() => _$ProductUnitToJson(this);
}

// ================= 3. PRODUCT MODEL =================
@JsonSerializable()
class Product {
  final int id;
  final String name;
  final String? sku;
  final String? description;
  final String? imageUrl;
  final int? categoryId;
  final String? baseUnit; // Tên đơn vị gốc từ server

  @JsonKey(defaultValue: [])
  final List<ProductUnit> productUnits;

  final Inventory? inventory;

  Product({
    required this.id,
    required this.name,
    this.sku,
    this.description,
    this.imageUrl,
    this.categoryId,
    this.baseUnit,
    required this.productUnits,
    this.inventory,
  });

  // --- GETTERS TIỆN ÍCH CHO UI ---

  // 1. Lấy số lượng tồn kho (An toàn null)
  double get inventoryQuantity => inventory?.quantity ?? 0.0;

  // 2. Lấy đơn vị tính mặc định (Ưu tiên BaseUnit -> Phần tử đầu -> Null)
  ProductUnit? get _defaultUnit {
    if (productUnits.isEmpty) return null;
    try {
      return productUnits.firstWhere((u) => u.isBaseUnit);
    } catch (e) {
      return productUnits.first;
    }
  }

  // 3. Các thuộc tính hiển thị nhanh
  double get price => _defaultUnit?.price ?? 0.0;
  String get unitName => _defaultUnit?.unitName ?? baseUnit ?? 'N/A';
  int get unitId => _defaultUnit?.id ?? 0;

  // 4. Tính tổng giá trị tồn kho của sản phẩm này (SL * Giá vốn/bán)
  double get totalInventoryValue => inventoryQuantity * price;

  // 5. Format tiền tệ nhanh (Optional)
  String get formattedPrice {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return format.format(price);
  }

  // --- COPY WITH NÂNG CAO ---
  // Cho phép update trực tiếp 'quantity' mà không cần tạo object Inventory thủ công
  Product copyWith({
    int? id,
    String? name,
    String? sku,
    String? description,
    String? imageUrl,
    int? categoryId,
    String? baseUnit,
    List<ProductUnit>? productUnits,
    Inventory? inventory,
    // Tham số phụ: Nếu truyền vào đây sẽ tự động update vào Inventory
    double? newQuantity,
  }) {
    // Logic xử lý Inventory mới
    Inventory? finalInventory = inventory ?? this.inventory;

    // Nếu có yêu cầu update số lượng (từ SignalR chẳng hạn)
    if (newQuantity != null) {
      if (finalInventory != null) {
        finalInventory = finalInventory.copyWith(quantity: newQuantity);
      } else {
        // Nếu chưa có inventory thì tạo mới
        finalInventory = Inventory(
          id: 0,
          productId: id ?? this.id,
          quantity: newQuantity,
          lastUpdated: DateTime.now().toIso8601String(),
        );
      }
    }

    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
      baseUnit: baseUnit ?? this.baseUnit,
      productUnits: productUnits ?? this.productUnits,
      inventory: finalInventory,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);
}
