class TrackingOrderItem {
  final String? sku;
  final String? name;
  final String? category;
  final num? price;
  final int? quantity;

  TrackingOrderItem({
    this.sku,
    this.name,
    this.category,
    this.price,
    this.quantity,
  });

  List<Object?> toArray() => [sku, name, category, price, quantity];
}
