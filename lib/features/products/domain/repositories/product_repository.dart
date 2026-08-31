import '../entities/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts();

  Future<Product> createProduct({
    required String name,
    required double sellingPrice,
    double? costPrice,
    String? sku,
    String? category,
    String? unit,
    String? notes,
  });

  Future<Product> updateProduct({
    required String id,
    required String name,
    required double sellingPrice,
    double? costPrice,
    String? sku,
    String? category,
    String? unit,
    String? notes,
  });

  Future<void> setProductActive({
    required String id,
    required bool active,
  });
}
