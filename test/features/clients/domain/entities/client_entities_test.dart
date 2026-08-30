import 'package:flutter_test/flutter_test.dart';

import 'package:asam_dev/features/clients/domain/entities/client.dart';
import 
'package:asam_dev/features/clients/domain/entities/marketing_interaction.dart';
import 'package:asam_dev/features/clients/domain/entities/order.dart';
import 
'package:asam_dev/features/clients/domain/entities/order_item.dart';
import 'package:asam_dev/features/clients/domain/entities/product.dart';
import 
'package:asam_dev/features/clients/domain/entities/supply_record.dart';

void main() {
  test('creates a client', () {
    const client = Client(
      id: 'client-1',
      name: 'ABC Stores',
      phone: '+263771234567',
      email: 'abc@example.com',
    );

    expect(client.id, 'client-1');
    expect(client.name, 'ABC Stores');
    expect(client.isActive, isTrue);
  });

  test('creates a product', () {
    const product = Product(
      id: 'product-1',
      name: 'Cooking Oil',
      sku: 'OIL-001',
      unit: 'litre',
    );

    expect(product.id, 'product-1');
    expect(product.name, 'Cooking Oil');
    expect(product.unit, 'litre');
  });

  test('creates a supply record', () {
    final suppliedAt = DateTime(2026, 8, 30);

    final record = SupplyRecord(
      id: 'supply-1',
      clientId: 'client-1',
      productId: 'product-1',
      quantity: 50,
      suppliedAt: suppliedAt,
    );

    expect(record.clientId, 'client-1');
    expect(record.productId, 'product-1');
    expect(record.quantity, 50);
    expect(record.suppliedAt, suppliedAt);
  });

  test('creates an order and order item', () {
    final orderedAt = DateTime(2026, 8, 30);

    final order = Order(
      id: 'order-1',
      clientId: 'client-1',
      orderedAt: orderedAt,
      status: 'pending',
    );

    const item = OrderItem(
      id: 'item-1',
      orderId: 'order-1',
      productId: 'product-1',
      quantity: 20,
    );

    expect(order.clientId, 'client-1');
    expect(order.status, 'pending');
    expect(item.orderId, 'order-1');
    expect(item.quantity, 20);
  });

  test('creates a marketing interaction', () {
    final occurredAt = DateTime(2026, 8, 30);

    final interaction = MarketingInteraction(
      id: 'interaction-1',
      clientId: 'client-1',
      occurredAt: occurredAt,
      type: 'follow_up',
      outcome: 'order_placed',
    );

    expect(interaction.clientId, 'client-1');
    expect(interaction.type, 'follow_up');
    expect(interaction.outcome, 'order_placed');
  });
}
