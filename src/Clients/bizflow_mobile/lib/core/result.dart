// lib/core/result.dart

sealed class Result<T> {
  const Result();

  double? get inventoryQuantity => null;
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final String message;
  final int? statusCode;
  const Failure(this.message, {this.statusCode});
}
