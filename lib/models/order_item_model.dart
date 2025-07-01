class OrderItem {
  final int id;
  final int orderId;
  final int menuItemId;
  final int quantity;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    required this.quantity,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'],
      orderId: map['orderId'],
      menuItemId: map['menuItemId'],
      quantity: map['quantity'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'menuItemId': menuItemId,
      'quantity': quantity,
    };
  }
}
