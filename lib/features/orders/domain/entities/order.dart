class OrderItem {
  const OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  final String productId;
  final String productName;
  final double quantity;
  final double unitPrice;

  double get total => quantity * unitPrice;
}

class AsamOrder {
  const AsamOrder({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.orderDate,
    required this.status,
    required this.totalAmount,
    this.notes,
  });

  final String id;
  final String clientId;
  final String clientName;
  final DateTime orderDate;
  final String status;
  final double totalAmount;
  final String? notes;

  bool get isOpen => status == 'draft' || status == 'confirmed';
}
