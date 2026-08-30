class OrderItem {
  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
  });

  final String id;
  final String orderId;
  final String productId;
  final double quantity;
}
