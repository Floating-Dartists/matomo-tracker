import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/matomo_tracker.dart';

import '../ressources/mock/data.dart';

void main() {
  TrackingOrderItem getTrackingOrderItem() {
    return const TrackingOrderItem(
      sku: trackingOrderItemSku,
      name: trackingOrderItemName,
      category: trackingOrderItemCategory,
      price: trackingOrderItemPrice,
      quantity: trackingOrderItemQuantity,
    );
  }

  test('it should be able to create TrackingOrderItem', () async {
    final trackingOrderItem = getTrackingOrderItem();

    expect(trackingOrderItem.sku, trackingOrderItemSku);
    expect(trackingOrderItem.name, trackingOrderItemName);
    expect(trackingOrderItem.category, trackingOrderItemCategory);
    expect(trackingOrderItem.price, trackingOrderItemPrice);
    expect(trackingOrderItem.quantity, trackingOrderItemQuantity);
  });

  test('it should be able to get TrackingOrderItem attribute in an array',
      () async {
    final trackingOrderItem = getTrackingOrderItem();
    final trackingOrderItemArray = trackingOrderItem.toArray();

    expect(trackingOrderItemArray, [
      trackingOrderItemSku,
      trackingOrderItemName,
      trackingOrderItemCategory,
      trackingOrderItemPrice,
      trackingOrderItemQuantity,
    ]);
  });
}
