class TrackingOrderItem {
  const TrackingOrderItem({
    required this.sku,
    this.name = '',
    this.category = '',
    this.price = 0,
    this.quantity = 1,
  });

  /// Item sku.
  final String sku;

  /// Item name (or if not applicable, should be an empty string)
  final String name;

  /// Item category (or if not applicable, should be an empty string)
  final String category;

  /// Item price (or if not applicable, should be set to 0)
  final num price;

  /// Item quantity (or if not applicable should be set to 1)
  final int quantity;

  List<Object> toArray() {
    return [
      sku,
      name,
      category,
      price,
      quantity,
    ];
  }
}
