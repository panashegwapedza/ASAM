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

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _errorMessage(Object error) => error is PostgrestException && error.message.trim().isNotEmpty
      ? error.message
      : error.toString();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(onPressed: _loading ? null : _loadOrders, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addOrder,
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Record Order'),
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: _loadOrders, child: const Text('Retry')),
        ]),
      ));
    }
    if (_ordersList.isEmpty) {
      return const Center(child: Text('No orders yet.\nRecord the first customer order.', textAlign: TextAlign.center));
    }
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _ordersList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, index) {
          final order = _ordersList[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(order.clientName),
              subtitle: Text('${_date(order.orderDate)} • ${order.status}'),
              trailing: Text(order.totalAmount.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          );
        },
      ),
    );
  }

  String _date(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

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
                subtitle: Text('${line.quantity:g} × ${(line.product.sellingPrice ?? 0).toStringAsFixed(2)}'),
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
