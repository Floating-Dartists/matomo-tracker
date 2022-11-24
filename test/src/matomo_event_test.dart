import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/src/matomo_event.dart';

import '../mock/data.dart';

void main() {
  test('it should be able to create MatomotoEvent', () async {
    final matomotoEvent = MatomoEvent(
      tracker: mockMatomoTracker,
      path: matomoEventPath,
      action: matomoEventAction,
      eventCategory: matomoEventCategory,
      dimensions: matomoEventDimension,
      discountAmount: matomoDiscountAmount,
      eventAction: matomoEventAction,
      eventValue: matomoEventValue,
      eventName: matomoEventName,
      goalId: matomoGoalId,
      link: matomoLink,
      orderId: matomoOrderId,
      revenue: matomoRevenue,
      screenId: matomoScreenId,
      searchCategory: matomoSearchCategory,
      searchCount: matomoSearchCount,
      searchKeyword: matomoSearchKeyword,
      shippingCost: matomoShippingCost,
      subTotal: matomoSubTotal,
      taxAmount: matomoTaxAmount,
      trackingOrderItems: matomoTrackingOrderItems,
    );

    expect(matomotoEvent.tracker, mockMatomoTracker);
    expect(matomotoEvent.path, matomoEventPath);
    expect(matomotoEvent.action, matomoEventAction);
    expect(matomotoEvent.eventCategory, matomoEventCategory);
    expect(matomotoEvent.dimensions, matomoEventDimension);
    expect(matomotoEvent.discountAmount, matomoDiscountAmount);
    expect(matomotoEvent.eventAction, matomoEventAction);
    expect(matomotoEvent.eventValue, matomoEventValue);
    expect(matomotoEvent.eventName, matomoEventName);
    expect(matomotoEvent.goalId, matomoGoalId);
    expect(matomotoEvent.link, matomoLink);
    expect(matomotoEvent.orderId, matomoOrderId);
    expect(matomotoEvent.revenue, matomoRevenue);
    expect(matomotoEvent.screenId, matomoScreenId);
    expect(matomotoEvent.searchCategory, matomoSearchCategory);
    expect(matomotoEvent.searchCount, matomoSearchCount);
    expect(matomotoEvent.searchKeyword, matomoSearchKeyword);
    expect(matomotoEvent.shippingCost, matomoShippingCost);
    expect(matomotoEvent.subTotal, matomoSubTotal);
    expect(matomotoEvent.taxAmount, matomoTaxAmount);
    expect(matomotoEvent.trackingOrderItems, matomoTrackingOrderItems);
  });

  test(
    'it should throw AssertionError if screen id is not 6 characters',
    () {
      MatomoEvent getMatomoEventWithWrongScreenId() {
        return MatomoEvent(
          tracker: mockMatomoTracker,
          screenId: matomoWrongScreenId,
        );
      }

      expect(
        getMatomoEventWithWrongScreenId,
        throwsA(isA<AssertionError>()),
      );
    },
  );

  test(
    'it should throw AssertionError if eventCategory is empty',
    () {
      MatomoEvent getMatomoEventWithEmptyEventCategory() {
        return MatomoEvent(
          tracker: mockMatomoTracker,
          eventCategory: '',
        );
      }

      expect(
        getMatomoEventWithEmptyEventCategory,
        throwsA(isA<AssertionError>()),
      );
    },
  );

  test(
    'it should throw AssertionError if eventAction is empty',
    () {
      MatomoEvent getMatomoEventWithEmptyEventAction() {
        return MatomoEvent(
          tracker: mockMatomoTracker,
          eventAction: '',
        );
      }

      expect(
        getMatomoEventWithEmptyEventAction,
        throwsA(isA<AssertionError>()),
      );
    },
  );

  test(
    'it should throw AssertionError if eventName is empty',
    () {
      MatomoEvent getMatomoEventWithEmptyEventName() {
        return MatomoEvent(
          tracker: mockMatomoTracker,
          eventName: '',
        );
      }

      expect(
        getMatomoEventWithEmptyEventName,
        throwsA(isA<AssertionError>()),
      );
    },
  );
}
