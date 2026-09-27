import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../clients/data/supabase_client_repository.dart';
import '../../clients/domain/entities/client.dart';
import '../../products/data/supabase_product_repository.dart';
import '../../products/domain/entities/product.dart';
import '../data/supabase_order_repository.dart';
import '../domain/entities/order.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late final SupabaseOrderRepository _orders;
  late final SupabaseClientRepository _clients;
  late final SupabaseProductRepository _products;

  List<AsamOrder> _ordersList = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _orders = SupabaseOrderRepository(client);
    _clients = SupabaseClientRepository(client);
    _products = SupabaseProductRepository(client);
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _orders.getOrders();
      if (!mounted) return;
      setState(() {
        _ordersList = rows;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _errorMessage(error);
        _loading = false;
      });
    }
  }

  Future<void> _addOrder() async {
    try {
      final clients = await _clients.getClients();
      final products = (await _products.getProducts()).where((p) => p.active).toList();
      if (!mounted) return;
      if (clients.isEmpty) {
        _snack('Add a client before recording an order.');
        return;
      }
      if (products.isEmpty) {
        _snack('Add at least one active product before recording an order.');
        return;
      }

      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _OrderDialog(
          clients: clients,
          products: products,
          repository: _orders,
        ),
      );
      if (result == true) await _loadOrders();
    } catch (error) {
      if (mounted) _snack(_errorMessage(error));
    }
  }

  Future<void> _changeStatus(AsamOrder order, String status) async {
    try {
      await _orders.updateOrderStatus(orderId: order.id, status: status);
      if (!mounted) return;
      _snack('Order status updated to ${_statusLabel(status)}.');
      await _loadOrders();
    } catch (error) {
      if (mounted) _snack(_errorMessage(error));
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _errorMessage(Object error) => error is PostgrestException && error.message.trim().isNotEmpty
      ? error.message
      : error.toString();

  String _statusLabel(String status) {
    switch (status) {
      case 'draft': return 'Draft';
      case 'confirmed': return 'Confirmed';
      case 'processing': return 'Processing';
      case 'completed': return 'Completed';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }

  List<String> _nextStatuses(String status) {
    switch (status) {
      case 'draft': return const ['confirmed', 'cancelled'];
      case 'confirmed': return const ['processing', 'cancelled'];
      case 'processing': return const ['completed', 'cancelled'];
      default: return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed = _ordersList.where((o) => o.status == 'completed').length;
    final open = _ordersList.where((o) => !['completed', 'cancelled'].contains(o.status)).length;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 28, 30, 34),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('SALES OPERATIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.7, color: Color(0xFF294B68))),
                        SizedBox(height: 7),
                        Text('Orders', style: TextStyle(fontSize: 36, height: 1.05, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
                        SizedBox(height: 7),
                        Text('Capture every order cleanly and keep fulfilment moving.', style: TextStyle(fontSize: 15, color: Color(0xFF69736D))),
                      ])),
                      const SizedBox(width: 18),
                      IconButton(onPressed: _loading ? null : _loadOrders, icon: const Icon(Icons.refresh), tooltip: 'Refresh'),
                      const SizedBox(width: 6),
                      FilledButton.icon(onPressed: _addOrder, icon: const Icon(Icons.add_shopping_cart), label: const Text('Record Order')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(children: [
                    _OrderStat(label: 'Total orders', value: '${_ordersList.length}', icon: Icons.receipt_long_outlined),
                    const SizedBox(width: 12),
                    _OrderStat(label: 'Open', value: '$open', icon: Icons.pending_actions_outlined),
                    const SizedBox(width: 12),
                    _OrderStat(label: 'Completed', value: '$completed', icon: Icons.task_alt_outlined),
                  ]),
                  const SizedBox(height: 20),
                  Expanded(child: Card(child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Order activity', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 5),
                      const Text('Track customers, totals and fulfilment state from one operational view.', style: TextStyle(fontSize: 13, color: Color(0xFF69736D))),
                      const SizedBox(height: 12),
                      Expanded(child: _buildOrderList()),
                    ]),
                  ))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline_rounded, size: 44, color: Color(0xFFC45C5C)),
      const SizedBox(height: 12),
      Text(_error!, textAlign: TextAlign.center),
      const SizedBox(height: 14),
      FilledButton(onPressed: _loadOrders, child: const Text('Retry')),
    ]));
    if (_ordersList.isEmpty) return const Center(child: Text('No orders yet.\nRecord the first customer order.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Color(0xFF69736D))));

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.separated(
        padding: const EdgeInsets.only(top: 6, bottom: 12),
        itemCount: _ordersList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 7),
        itemBuilder: (_, index) {
          final order = _ordersList[index];
          final next = _nextStatuses(order.status);
          final completed = order.status == 'completed';
          final cancelled = order.status == 'cancelled';
          final tone = cancelled ? const Color(0xFFC45C5C) : completed ? const Color(0xFF3A7A58) : const Color(0xFF294B68);
          return Container(
            decoration: BoxDecoration(color: const Color(0xFFF8FAF8), borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFE0E5E2))),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
              child: Row(children: [
                Container(width: 46, height: 46, decoration: BoxDecoration(color: tone.withOpacity(.10), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.receipt_long_outlined, color: tone)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(order.clientName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('${_date(order.orderDate)} • ${_statusLabel(order.status)}', style: const TextStyle(fontSize: 13, color: Color(0xFF69736D))),
                  if (next.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 7, runSpacing: 6, children: next.map((status) => OutlinedButton(onPressed: () => _changeStatus(order, status), child: Text(_statusLabel(status)))).toList()),
                  ],
                ])),
                const SizedBox(width: 14),
                Text(order.totalAmount.toStringAsFixed(2), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ]),
            ),
          );
        },
      ),
    );
  }

  String _date(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class _OrderLine {
  _OrderLine(this.product, this.quantity);
  final Product product;
  double quantity;

  double get total => quantity * (product.sellingPrice ?? 0);
}

class _OrderDialog extends StatefulWidget {
  const _OrderDialog({required this.clients, required this.products, required this.repository});
  final List<Client> clients;
  final List<Product> products;
  final SupabaseOrderRepository repository;

  @override
  State<_OrderDialog> createState() => _OrderDialogState();
}

class _OrderDialogState extends State<_OrderDialog> {
  late Client _client;
  late DateTime _date;
  final _notes = TextEditingController();
  final List<_OrderLine> _lines = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _client = widget.clients.first;
    _date = DateTime.now();
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  double get _total => _lines.fold(0, (sum, line) => sum + line.total);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: _date);
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _addLine() async {
    final available = widget.products.where((product) => !_lines.any((line) => line.product.id == product.id)).toList();
    if (available.isEmpty) return;
    Product selected = available.first;
    final quantity = TextEditingController(text: '1');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add product'),
        content: StatefulBuilder(builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Product>(
              value: selected,
              items: available.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
              onChanged: (value) => setState(() => selected = value ?? selected),
              decoration: const InputDecoration(labelText: 'Product'),
            ),
            TextField(
              controller: quantity,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
          ],
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    );
    final qty = double.tryParse(quantity.text.trim());
    quantity.dispose();
    if (ok == true && qty != null && qty > 0 && mounted) {
      setState(() => _lines.add(_OrderLine(selected, qty)));
    }
  }

  Future<void> _save() async {
    if (_saving || _lines.isEmpty) {
      if (_lines.isEmpty) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one product.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.repository.createOrder(
        clientId: _client.id,
        orderDate: _date,
        items: _lines.map((line) => OrderItem(
          productId: line.product.id,
          productName: line.product.name,
          quantity: line.quantity,
          unitPrice: line.product.sellingPrice ?? 0,
        )).toList(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error is PostgrestException ? error.message : error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record Order'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            DropdownButtonFormField<Client>(
              value: _client,
              items: widget.clients.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
              onChanged: _saving ? null : (value) { if (value != null) setState(() => _client = value); },
              decoration: const InputDecoration(labelText: 'Client'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Order date'),
              subtitle: Text('${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}'),
              trailing: IconButton(onPressed: _saving ? null : _pickDate, icon: const Icon(Icons.calendar_today_outlined)),
            ),
            const Divider(),
            if (_lines.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('No products added.', textAlign: TextAlign.center))
            else
              ..._lines.map((line) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(line.product.name),
                subtitle: Text('${line.quantity} × ${(line.product.sellingPrice ?? 0).toStringAsFixed(2)}'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(line.total.toStringAsFixed(2)),
                  IconButton(onPressed: _saving ? null : () => setState(() => _lines.remove(line)), icon: const Icon(Icons.delete_outline)),
                ]),
              )),
            OutlinedButton.icon(onPressed: _saving ? null : _addLine, icon: const Icon(Icons.add), label: const Text('Add Product')),
            const SizedBox(height: 8),
            TextField(controller: _notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Notes')),
            const SizedBox(height: 16),
            Align(alignment: Alignment.centerRight, child: Text('Total: ${_total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge)),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: Text(_saving ? 'Saving…' : 'Save Order')),
      ],
    );
  }
}
