// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_import.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StockImport _$StockImportFromJson(Map<String, dynamic> json) => StockImport(
      id: (json['id'] as num).toInt(),
      productName: json['productName'] as String,
      unitName: json['unitName'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unitCost: (json['unitCost'] as num).toDouble(),
      supplierName: json['supplierName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      note: json['note'] as String?,
    );

Map<String, dynamic> _$StockImportToJson(StockImport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'productName': instance.productName,
      'unitName': instance.unitName,
      'quantity': instance.quantity,
      'unitCost': instance.unitCost,
      'supplierName': instance.supplierName,
      'createdAt': instance.createdAt.toIso8601String(),
      'note': instance.note,
    };
