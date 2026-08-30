class Order {
  const Order({
    required this.id,
    required this.clientId,
    required this.orderedAt,
    required this.status,
  });

  final String id;
  final String clientId;
  final DateTime orderedAt;
  final String status;
}
