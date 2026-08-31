class Product {
  const Product({
    required this.id,
    required this.name,
    required this.unit,
    this.sku,
    this.category,
    this.costPrice,
    this.sellingPrice,
    this.active = true,
    this.notes,
  });

  final String id;
  final String name;
  final String? sku;
  final String? category;
  final String unit;
  final double? costPrice;
  final double? sellingPrice;
  final bool active;
  final String? notes;

  double get profitMargin {
    final cost = costPrice;
    final selling = sellingPrice;

    if (cost == null || selling == null || selling == 0) {
      return 0;
    }

    return ((selling - cost) / selling) * 100;
  }
}
