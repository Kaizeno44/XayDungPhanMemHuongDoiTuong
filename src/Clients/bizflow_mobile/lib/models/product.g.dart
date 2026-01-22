// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductUnit _$ProductUnitFromJson(Map<String, dynamic> json) => ProductUnit(
      id: (json['id'] as num).toInt(),
      unitName: json['unitName'] as String,
      price: (json['price'] as num).toDouble(),
      isBaseUnit: json['isBaseUnit'] as bool? ?? false,
    );

Map<String, dynamic> _$ProductUnitToJson(ProductUnit instance) =>
    <String, dynamic>{
      'id': instance.id,
      'unitName': instance.unitName,
      'price': instance.price,
      'isBaseUnit': instance.isBaseUnit,
    };

Product _$ProductFromJson(Map<String, dynamic> json) => Product(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      productUnits: (json['productUnits'] as List<dynamic>?)
              ?.map((e) => ProductUnit.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      inventoryQuantity:
          (Product._readInventoryQuantity(json, 'inventoryQuantity') as num?)
                  ?.toDouble() ??
              0.0,
    );

Map<String, dynamic> _$ProductToJson(Product instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'imageUrl': instance.imageUrl,
      'productUnits': instance.productUnits,
      'inventoryQuantity': instance.inventoryQuantity,
    };
