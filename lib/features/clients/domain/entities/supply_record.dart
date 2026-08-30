class SupplyRecord {
  const SupplyRecord({
    required this.id,
    required this.clientId,
    required this.productId,
    required this.quantity,
    required this.suppliedAt,
  });

  final String id;
  final String clientId;
  final String productId;
  final double quantity;
  final DateTime suppliedAt;
}
