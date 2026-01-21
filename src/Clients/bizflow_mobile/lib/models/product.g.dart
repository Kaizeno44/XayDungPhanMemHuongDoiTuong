// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Inventory _$InventoryFromJson(Map<String, dynamic> json) => Inventory(
      id: (json['id'] as num).toInt(),
      productId: (json['productId'] as num).toInt(),
      quantity: (json['quantity'] as num).toDouble(),
      lastUpdated: json['lastUpdated'] as String?,
    );

Map<String, dynamic> _$InventoryToJson(Inventory instance) => <String, dynamic>{
      'id': instance.id,
      'productId': instance.productId,
      'quantity': instance.quantity,
      'lastUpdated': instance.lastUpdated,
    };

ProductUnit _$ProductUnitFromJson(Map<String, dynamic> json) => ProductUnit(
      id: (json['id'] as num).toInt(),
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      unitName: json['unitName'] as String,
      price: (json['price'] as num).toDouble(),
      conversionValue: (json['conversionValue'] as num?)?.toDouble() ?? 1.0,
      isBaseUnit: json['isBaseUnit'] as bool? ?? false,
    );

Map<String, dynamic> _$ProductUnitToJson(ProductUnit instance) =>
    <String, dynamic>{
      'id': instance.id,
      'productId': instance.productId,
      'unitName': instance.unitName,
      'price': instance.price,
      'conversionValue': instance.conversionValue,
      'isBaseUnit': instance.isBaseUnit,
    };

Product _$ProductFromJson(Map<String, dynamic> json) => Product(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      sku: json['sku'] as String?,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      categoryId: (json['categoryId'] as num?)?.toInt(),
      baseUnit: json['baseUnit'] as String?,
      productUnits: (json['productUnits'] as List<dynamic>?)
              ?.map((e) => ProductUnit.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      inventory: json['inventory'] == null
          ? null
          : Inventory.fromJson(json['inventory'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ProductToJson(Product instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'sku': instance.sku,
      'description': instance.description,
      'imageUrl': instance.imageUrl,
      'categoryId': instance.categoryId,
      'baseUnit': instance.baseUnit,
      'productUnits': instance.productUnits,
      'inventory': instance.inventory,
    };
