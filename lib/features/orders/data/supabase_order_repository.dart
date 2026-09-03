import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/order.dart';

class SupabaseOrderRepository {
  const SupabaseOrderRepository(this._client);

  final SupabaseClient _client;

  String get _ownerId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw AuthException('No authenticated Supabase session.');
    }
    return user.id;
  }

  Future<List<AsamOrder>> getOrders() async {
    final rows = await _client
        .from('orders')
        .select('id, client_id, order_date, status, total_amount, notes, clients(name)')
        .eq('owner_id', _ownerId)
        .order('order_date', ascending: false)
        .order('created_at', ascending: false);

    return (rows as List).map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      final client = map['clients'] is Map
          ? Map<String, dynamic>.from(map['clients'] as Map)
          : <String, dynamic>{};
      return AsamOrder(
        id: map['id'].toString(),
        clientId: map['client_id'].toString(),
        clientName: client['name']?.toString() ?? 'Unknown client',
        orderDate: DateTime.parse(map['order_date'].toString()),
        status: map['status']?.toString() ?? 'draft',
        totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
        notes: map['notes'] as String?,
      );
    }).toList();
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    const allowed = {'draft', 'confirmed', 'processing', 'completed', 'cancelled'};
    if (!allowed.contains(status)) {
      throw ArgumentError('Unsupported order status: $status');
    }

    await _client
        .from('orders')
        .update({'status': status})
        .eq('id', orderId)
        .eq('owner_id', _ownerId);
  }

  Future<AsamOrder> createOrder({
    required String clientId,
    required DateTime orderDate,
    required List<OrderItem> items,
    String status = 'completed',
    String? notes,
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('An order must contain at least one product.');
    }

    final ownerId = _ownerId;
    final total = items.fold<double>(0, (sum, item) => sum + item.total);

    final order = await _client.from('orders').insert({
      'owner_id': ownerId,
      'client_id': clientId,
      'order_date': orderDate.toIso8601String().substring(0, 10),
      'status': status,
      'total_amount': total,
      'notes': notes,
    }).select('id, client_id, order_date, status, total_amount, notes, clients(name)').single();

    try {
      await _client.from('order_items').insert(
        items
            .map((item) => {
                  'order_id': order['id'],
                  'product_id': item.productId,
                  'quantity': item.quantity,
                  'unit_price': item.unitPrice,
                })
            .toList(),
      );
    } catch (_) {
      await _client.from('orders').delete().eq('id', order['id']).eq('owner_id', ownerId);
      rethrow;
    }

    final client = order['clients'] is Map
        ? Map<String, dynamic>.from(order['clients'] as Map)
        : <String, dynamic>{};
    return AsamOrder(
      id: order['id'].toString(),
      clientId: order['client_id'].toString(),
      clientName: client['name']?.toString() ?? 'Unknown client',
      orderDate: DateTime.parse(order['order_date'].toString()),
      status: order['status'].toString(),
      totalAmount: (order['total_amount'] as num?)?.toDouble() ?? total,
      notes: order['notes'] as String?,
    );
  }
}
