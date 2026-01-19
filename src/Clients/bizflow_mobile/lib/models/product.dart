import 'package:json_annotation/json_annotation.dart';

part 'product.g.dart';

@JsonSerializable()
class ProductUnit {
  final int id;
  final String unitName;
  final double price;

  @JsonKey(defaultValue: false)
  final bool isBaseUnit;

  ProductUnit({
    required this.id,
    required this.unitName,
    required this.price,
    required this.isBaseUnit,
  });

  factory ProductUnit.fromJson(Map<String, dynamic> json) =>
      _$ProductUnitFromJson(json);
  Map<String, dynamic> toJson() => _$ProductUnitToJson(this);
}

@JsonSerializable()
class Product {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;

  @JsonKey(defaultValue: [])
  final List<ProductUnit> productUnits;

  // 👇 LOGIC MỚI: Đọc nested JSON (inventory.quantity)
  @JsonKey(readValue: _readInventoryQuantity)
  final double inventoryQuantity;

  Product({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.productUnits,
    this.inventoryQuantity = 0.0,
  });

  // Helper function để đọc dữ liệu lồng nhau
  static Object? _readInventoryQuantity(Map map, String key) {
    if (map['inventory'] != null && map['inventory'] is Map) {
      return map['inventory']['quantity'];
    }
    return map['inventoryQuantity'] ?? 0.0;
  }

  // CopyWith giữ nguyên để update state
  Product copyWith({
    int? id,
    String? name,
    String? description,
    String? imageUrl,
    List<ProductUnit>? productUnits,
    double? inventoryQuantity,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      productUnits: productUnits ?? this.productUnits,
      inventoryQuantity: inventoryQuantity ?? this.inventoryQuantity,
    );
  }

  // Getters tiện ích
  ProductUnit? get _defaultUnit {
    if (productUnits.isEmpty) return null;
    return productUnits.firstWhere(
      (u) => u.isBaseUnit,
      orElse: () => productUnits.first,
    );
  }

  double get basePrice => _defaultUnit?.price ?? 0.0;
  int get unitId => _defaultUnit?.id ?? 0;
  String get unitName => _defaultUnit?.unitName ?? '';
  double get price => basePrice;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);
}
