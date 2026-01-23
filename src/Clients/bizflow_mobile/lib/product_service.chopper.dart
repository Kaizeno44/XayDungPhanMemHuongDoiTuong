// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_service.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$ProductService extends ProductService {
  _$ProductService([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = ProductService;

  @override
  Future<Response<dynamic>> getProducts({
    String? keyword,
    int? categoryId,
    int page = 1,
    int pageSize = 10,
  }) {
    final Uri $url = Uri.parse('/api/Products');
    final Map<String, dynamic> $params = <String, dynamic>{
      'keyword': keyword,
      'categoryId': categoryId,
      'page': page,
      'pageSize': pageSize,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> getProductById(int id) {
    final Uri $url = Uri.parse('/api/Products/${id}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> importStock(Map<String, dynamic> body) {
    final Uri $url = Uri.parse('/api/StockImports');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> getStockHistory({required String storeId}) {
    final Uri $url = Uri.parse('/api/StockImports');
    final Map<String, dynamic> $params = <String, dynamic>{'storeId': storeId};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> checkStock(Map<String, dynamic> body) {
    final Uri $url = Uri.parse('/api/Products/check-stock');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }
}
