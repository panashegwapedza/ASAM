import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    if (error.code.trim().isNotEmpty) parts.add('code ${error.code}');
    return parts.isEmpty ? 'Supabase request failed.' : parts.join(' — ');
  }

  String _price(Product product) {
    final price = product.sellingPrice;
    return price == null ? 'Price not set' : price.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadProducts,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProductDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Could not load products.',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loadProducts,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return const Center(
        child: Text(
          'No products yet.\nAdd your first product.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  product.name.isEmpty ? '?' : product.name[0].toUpperCase(),
                ),
              ),
              title: Text(product.name),
              subtitle: Text(
                '${product.category ?? 'Uncategorised'} • '
                '${product.unit} • Price: ${_price(product)}',
              ),
              trailing: Icon(
                product.active
                    ? Icons.check_circle_outline
                    : Icons.pause_circle_outline,
              ),
            ),
          );
        },
      ),
    );
  }
}
