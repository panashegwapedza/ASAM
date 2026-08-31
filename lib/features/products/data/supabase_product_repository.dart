import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/product.dart';
import '../domain/repositories/product_repository.dart';

class SupabaseProductRepository implements ProductRepository {
  SupabaseProductRepository(this._client);

  final SupabaseClient _client;

  Product _fromRow(Map<String, dynamic> row) {
    return Product(
      id: row['id'].toString(),
      name: row['name'] as String,
      sku: row['sku'] as String?,
      category: row['category'] as String?,
      unit: row['unit'] as String,
      costPrice: (row['cost_price'] as num?)?.toDouble(),
      sellingPrice: (row['selling_price'] as num?)?.toDouble() ?? 0,
      active: (row['active'] as bool?) ?? true,
      notes: row['notes'] as String?,
    );
  }

  @override
  Future<List<Product>> getProducts() async {
    final response = await _client
        .from('products')
        .select()
        .order('name');

    return (response as List)
        .map((row) => _fromRow(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Product> createProduct({
    required String name,
    required double sellingPrice,
    double? costPrice,
    String? sku,
    String? category,
    String? unit,
    String? notes,
  }) async {
    final response = await _client
        .from('products')
        .insert({
          'name': name,
          'selling_price': sellingPrice,
          'cost_price': costPrice,
          'sku': sku,
          'category': category,
          'unit': unit ?? 'unit',
          'notes': notes,
          'active': true,
        })
        .select()
        .single();

    return _fromRow(response);
  }

  @override
  Future<Product> updateProduct({
    required String id,
    required String name,
    required double sellingPrice,
    double? costPrice,
    String? sku,
    String? category,
    String? unit,
    String? notes,
  }) async {
    final response = await _client
        .from('products')
        .update({
          'name': name,
          'selling_price': sellingPrice,
          'cost_price': costPrice,
          'sku': sku,
          'category': category,
          'unit': unit ?? 'unit',
          'notes': notes,
        })
        .eq('id', id)
        .select()
        .single();

    return _fromRow(response);
  }

  @override
  Future<void> setProductActive({
    required String id,
    required bool active,
  }) async {
    await _client
        .from('products')
        .update({'active': active})
        .eq('id', id);
  }
}
