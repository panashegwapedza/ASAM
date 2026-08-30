class Product {
  const Product({
    required this.id,
    required this.name,
    this.sku,
    this.unit,
  });

  final String id;
  final String name;
  final String? sku;
  final String? unit;
}
