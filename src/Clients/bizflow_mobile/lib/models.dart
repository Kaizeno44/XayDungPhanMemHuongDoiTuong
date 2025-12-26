class CartItem {
  final int productId;
  final String productName;
  final int unitId;
  final String unitName;
  final double price;
  int quantity;

  CartItem({
    required this.productId,
    required this.productName,
    required this.unitId,
    required this.unitName,
    required this.price,
    this.quantity = 1,
  });

  double get total => price * quantity;

  Map<String, dynamic> toJson() {
    return {
      "productId": productId,
      "unitId": unitId,
      "quantity": quantity,
    };
  }
}

class Customer {
  final String id;
  final String name;
  Customer({required this.id, required this.name});
}