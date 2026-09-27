import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../clients/data/supabase_client_repository.dart';
import '../../clients/domain/entities/client.dart';
import '../../orders/data/supabase_order_repository.dart';
import '../../orders/domain/entities/order.dart';
import '../data/supabase_product_repository.dart';
import '../domain/entities/product.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late final SupabaseProductRepository _repository;

  List<Product> _products = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = SupabaseProductRepository(Supabase.instance.client);
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final products = await _repository.getProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _loading = false;
      });
    } on PostgrestException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _postgrestMessage(error);
        _loading = false;
      });
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _quickOrder(Product product) async {
    final clientsRepository = SupabaseClientRepository(Supabase.instance.client);
    final ordersRepository = SupabaseOrderRepository(Supabase.instance.client);

    try {
      final clients = await clientsRepository.getClients();
      if (!mounted) return;

      if (clients.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add a client before placing an order.')),
        );
        return;
      }

      final quantityController = TextEditingController(text: '1');
      Client selectedClient = clients.first;

      try {
        final saved = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            var saving = false;

            return StatefulBuilder(
              builder: (context, setDialogState) {
                Future<void> save() async {
                  if (saving) return;
                  final quantity = double.tryParse(quantityController.text.trim());
                  if (quantity == null || quantity <= 0) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('Enter a quantity greater than zero.')),
                    );
                    return;
                  }

                  setDialogState(() => saving = true);
                  try {
                    await ordersRepository.createOrder(
                      clientId: selectedClient.id,
                      orderDate: DateTime.now(),
                      items: [
                        OrderItem(
                          productId: product.id,
                          productName: product.name,
                          quantity: quantity,
                          unitPrice: product.sellingPrice ?? 0,
                        ),
                      ],
                      status: 'completed',
                    );

                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop(true);
                    }
                  } catch (error) {
                    if (!dialogContext.mounted) return;
                    setDialogState(() => saving = false);
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text(_errorMessage(error))),
                    );
                  }
                }

                return AlertDialog(
                  title: Text('Order ${product.name}'),
                  content: SizedBox(
                    width: 460,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<Client>(
                          value: selectedClient,
                          items: clients
                              .map(
                                (client) => DropdownMenuItem<Client>(
                                  value: client,
                                  child: Text(client.name),
                                ),
                              )
                              .toList(),
                          onChanged: saving
                              ? null
                              : (client) {
                                  if (client != null) {
                                    setDialogState(() => selectedClient = client);
                                  }
                                },
                          decoration: const InputDecoration(labelText: 'Client'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: quantityController,
                          enabled: !saving,
                          autofocus: true,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Quantity',
                            suffixText: product.unit,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Total: ${((product.sellingPrice ?? 0) * (double.tryParse(quantityController.text) ?? 1)).toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: saving
                          ? null
                          : () => Navigator.of(dialogContext).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton.icon(
                      onPressed: saving ? null : save,
                      icon: saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.shopping_cart_checkout),
                      label: Text(saving ? 'Saving…' : 'Place Order'),
                    ),
                  ],
                );
              },
            );
          },
        );

        if (saved == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Order placed for ${product.name}.')),
          );
        }
      } finally {
        quantityController.dispose();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage(error))),
        );
      }
    }
  }

  Future<void> _showAddProductDialog() async {
    final nameController = TextEditingController();
    final skuController = TextEditingController();
    final categoryController = TextEditingController();
    final unitController = TextEditingController(text: 'unit');
    final costController = TextEditingController();
    final sellingController = TextEditingController();
    final notesController = TextEditingController();
    var saving = false;

    try {
      final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          final screenHeight = MediaQuery.sizeOf(dialogContext).height;
          final maxDialogHeight = (screenHeight - 96).clamp(320.0, 680.0);

          return StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> save() async {
                if (saving) return;

                final name = nameController.text.trim();
                final unit = unitController.text.trim();
                final sellingPrice = double.tryParse(
                  sellingController.text.trim(),
                );
                final costPrice = double.tryParse(costController.text.trim());

                if (name.isEmpty || unit.isEmpty || sellingPrice == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Enter a product name, unit and valid selling price.',
                      ),
                    ),
                  );
                  return;
                }

                if (costController.text.trim().isNotEmpty &&
                    costPrice == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Enter a valid cost price or leave it blank.'),
                    ),
                  );
                  return;
                }

                setDialogState(() => saving = true);

                try {
                  await _repository.createProduct(
                    name: name,
                    unit: unit,
                    sku: _nullable(skuController.text),
                    category: _nullable(categoryController.text),
                    costPrice: costPrice,
                    sellingPrice: sellingPrice,
                    notes: _nullable(notesController.text),
                  );

                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop(true);
                } on PostgrestException catch (error) {
                  if (!dialogContext.mounted) return;
                  setDialogState(() => saving = false);
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(_postgrestMessage(error))),
                  );
                } on AuthException catch (error) {
                  if (!dialogContext.mounted) return;
                  setDialogState(() => saving = false);
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(error.message)),
                  );
                } catch (error) {
                  if (!dialogContext.mounted) return;
                  setDialogState(() => saving = false);
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(error.toString())),
                  );
                }
              }

              return AlertDialog(
                title: const Text('Add Product'),
                content: SizedBox(
                  width: 520,
                  height: maxDialogHeight,
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          autofocus: true,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Product name *',
                          ),
                        ),
                        TextField(
                          controller: skuController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'SKU'),
                        ),
                        TextField(
                          controller: categoryController,
                          textInputAction: TextInputAction.next,
                          decoration:
                              const InputDecoration(labelText: 'Category'),
                        ),
                        TextField(
                          controller: unitController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'Unit *'),
                        ),
                        TextField(
                          controller: costController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.next,
                          decoration:
                              const InputDecoration(labelText: 'Cost price'),
                        ),
                        TextField(
                          controller: sellingController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Selling price *',
                          ),
                        ),
                        TextField(
                          controller: notesController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(labelText: 'Notes'),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: saving
                        ? null
                        : () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton.icon(
                    onPressed: saving ? null : save,
                    icon: saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(saving ? 'Saving…' : 'Save'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (saved == true) {
        await _loadProducts();
      }
    } finally {
      nameController.dispose();
      skuController.dispose();
      categoryController.dispose();
      unitController.dispose();
      costController.dispose();
      sellingController.dispose();
      notesController.dispose();
    }
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _postgrestMessage(PostgrestException error) {
    final parts = <String>[];
    if (error.message.trim().isNotEmpty) parts.add(error.message.trim());
    if (error.details?.toString().trim().isNotEmpty == true) {
      parts.add(error.details.toString().trim());
    }
    if (error.hint?.toString().trim().isNotEmpty == true) {
      parts.add(error.hint.toString().trim());
    }
    final code = error.code?.trim();
    if (code != null && code.isNotEmpty) parts.add('code $code');
    return parts.isEmpty ? 'Supabase request failed.' : parts.join(' — ');
  }

  String _errorMessage(Object error) {
    if (error is PostgrestException) return _postgrestMessage(error);
    if (error is AuthException) return error.message;
    return error.toString();
  }

  String _price(Product product) {
    final price = product.sellingPrice;
    return price == null ? 'Price not set' : price.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final active = _products.where((p) => p.active).length;
    final categories = _products.map((p) => p.category).whereType<String>().where((v) => v.isNotEmpty).toSet().length;

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
                      const Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('CATALOGUE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.7, color: Color(0xFF294B68))),
                          SizedBox(height: 7),
                          Text('Products', style: TextStyle(fontSize: 36, height: 1.05, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
                          SizedBox(height: 7),
                          Text('Keep the catalogue clean, commercial and ready for the next order.', style: TextStyle(fontSize: 15, color: Color(0xFF69736D))),
                        ]),
                      ),
                      const SizedBox(width: 18),
                      IconButton(onPressed: _loading ? null : _loadProducts, icon: const Icon(Icons.refresh), tooltip: 'Refresh'),
                      const SizedBox(width: 6),
                      FilledButton.icon(onPressed: _showAddProductDialog, icon: const Icon(Icons.add), label: const Text('Add Product')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(children: [
                    _ProductStat(label: 'Total products', value: '${_products.length}', icon: Icons.inventory_2_outlined),
                    const SizedBox(width: 12),
                    _ProductStat(label: 'Active', value: '$active', icon: Icons.check_circle_outline),
                    const SizedBox(width: 12),
                    _ProductStat(label: 'Categories', value: '$categories', icon: Icons.category_outlined),
                  ]),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Product catalogue', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 5),
                          const Text('Products are the commercial building blocks behind orders and client activity.', style: TextStyle(fontSize: 13, color: Color(0xFF69736D))),
                          const SizedBox(height: 12),
                          Expanded(child: _buildProductList()),
                        ]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline_rounded, size: 44, color: Color(0xFFC45C5C)),
      const SizedBox(height: 12),
      const Text('Could not load products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      Text(_error!, textAlign: TextAlign.center),
      const SizedBox(height: 14),
      FilledButton(onPressed: _loadProducts, child: const Text('Retry')),
    ]));
    if (_products.isEmpty) return const Center(child: Text('No products yet.\nAdd your first product.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Color(0xFF69736D))));

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.separated(
        padding: const EdgeInsets.only(top: 6, bottom: 12),
        itemCount: _products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 7),
        itemBuilder: (context, index) {
          final product = _products[index];
          final canOrder = product.active && product.sellingPrice != null;
          return Container(
            decoration: BoxDecoration(color: const Color(0xFFF8FAF8), borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFE0E5E2))),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              leading: Container(
                width: 46, height: 46,
                decoration: BoxDecoration(color: const Color(0xFFE8F0F5), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.inventory_2_outlined, color: const Color(0xFF294B68)),
              ),
              title: Text(product.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${product.category ?? 'Uncategorised'} • ${product.unit} • Price: ${_price(product)}', style: const TextStyle(fontSize: 13, color: Color(0xFF69736D))),
              ),
              trailing: Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                if (canOrder) OutlinedButton.icon(onPressed: () => _quickOrder(product), icon: const Icon(Icons.shopping_cart_outlined, size: 18), label: const Text('Order')),
                Icon(product.active ? Icons.check_circle_outline : Icons.pause_circle_outline, color: product.active ? const Color(0xFF3A7A58) : const Color(0xFF69736D)),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _ProductStat extends StatelessWidget {
  const _ProductStat({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [
    Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: const Color(0xFFE5EEF4), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: const Color(0xFF294B68), size: 23)),
    const SizedBox(width: 13),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF69736D), fontWeight: FontWeight.w600)),
      const SizedBox(height: 3),
      Text(value, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
    ]),
  ])));
}
