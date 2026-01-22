import 'package:json_annotation/json_annotation.dart';

part 'product.g.dart';

// ================= 1. INVENTORY MODEL =================
// Tách riêng để dễ dàng update qua SignalR (copyWith)
@JsonSerializable()
class Inventory {
  final int id;
  final int productId;
  final double quantity;
  final String? lastUpdated;

  Inventory({
    required this.id,
    required this.productId,
    required this.quantity,
    this.lastUpdated,
  });

  // CopyWith để update số lượng khi có tin từ SignalR
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

  // Xử lý trường hợp server trả về id khác null
  @JsonKey(defaultValue: 0)
  final int productId;

  final String unitName;
  final double price;
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
  final String? sku; // Mã sản phẩm
  final String? description;
  final String? imageUrl;
  final int? categoryId;
  final String? baseUnit; // Đơn vị gốc (string) từ server

  @JsonKey(defaultValue: [])
  final List<ProductUnit> productUnits;

  // Thay vì dùng readValue, ta map thẳng vào object Inventory
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

  // 2. Lấy đơn vị tính mặc định (ưu tiên isBaseUnit -> phần tử đầu -> chuỗi baseUnit)
  ProductUnit? get _defaultUnit {
    if (productUnits.isEmpty) return null;
    return productUnits.firstWhere(
      (u) => u.isBaseUnit,
      orElse: () => productUnits.first,
    );
  }

  // 3. Các thuộc tính hiển thị
  double get price => _defaultUnit?.price ?? 0.0;
  String get unitName => _defaultUnit?.unitName ?? baseUnit ?? '';
  int get unitId => _defaultUnit?.id ?? 0;

  // --- COPY WITH (QUAN TRỌNG CHO RIVERPOD) ---
  Product copyWith({
    int? id,
    String? name,
    String? sku,
    String? description,
    String? imageUrl,
    Inventory? inventory,
    List<ProductUnit>? productUnits,
    required double inventoryQuantity,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      // Các trường ít thay đổi có thể giữ nguyên từ this
      categoryId: this.categoryId,
      baseUnit: this.baseUnit,

      // Các trường hay thay đổi
      inventory: inventory ?? this.inventory,
      productUnits: productUnits ?? this.productUnits,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);
}
