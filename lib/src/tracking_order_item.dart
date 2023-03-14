class TrackingOrderItem {
  TrackingOrderItem({
    this.sku,
    this.name,
    this.category,
    this.price,
    this.quantity,
  });

  final String? sku;
  final String? name;
  final String? category;
  final num? price;
  final int? quantity;

  List<Object?> toArray() => [sku, name, category, price, quantity];
}
