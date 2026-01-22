class StockUpdateEvent {
  final int productId;
  final double newQuantity;

  StockUpdateEvent({required this.productId, required this.newQuantity});

  @override
  String toString() => 'StockUpdateEvent(id: $productId, qty: $newQuantity)';
}
