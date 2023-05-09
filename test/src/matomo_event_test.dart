import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/src/matomo_event.dart';
import 'package:mocktail/mocktail.dart';

import '../ressources/mock/data.dart';
import '../ressources/mock/mock.dart';

void main() {
  MatomoEvent getCompleteMatomoEvent() {
    return MatomoEvent(
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
  }

  test('it should be able to create MatomotoEvent', () async {
    final matomotoEvent = getCompleteMatomoEvent();

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

  group(
    'AssertionError checking',
    () {
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
            throwsAssertionError,
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
            throwsAssertionError,
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
            throwsAssertionError,
          );
        },
      );

      test('it should throw AssertionError if eventName is empty', () {
        MatomoEvent getMatomoEventWithEmptyEventName() {
          return MatomoEvent(
            tracker: mockMatomoTracker,
            eventName: '',
          );
        }

        expect(
          getMatomoEventWithEmptyEventName,
          throwsAssertionError,
        );
      });
    },
  );

  group('toMap', () {
    setUpAll(() {
      when(() => mockMatomoTracker.visitor).thenReturn(mockVisitor);
      when(() => mockMatomoTracker.session).thenReturn(mockSession);
      when(() => mockMatomoTracker.screenResolution)
          .thenReturn(matomoTrackerScreenResolution);
      when(() => mockMatomoTracker.contentBase)
          .thenReturn(matomoTrackerContentBase);
      when(() => mockMatomoTracker.siteId).thenReturn(matomoTrackerSiteId);
      when(() => mockVisitor.id).thenReturn(visitorId);
      when(() => mockVisitor.cid).thenReturn(cid);
      when(() => mockVisitor.userId).thenReturn(userId);
      when(mockTrackingOrderItem.toArray).thenReturn([]);
      when(() => mockSession.visitCount).thenReturn(sessionVisitCount);
      when(() => mockSession.lastVisit).thenReturn(sessionLastVisite);
      when(() => mockSession.firstVisit).thenReturn(sessionFirstVisite);
    });

    test('it should be able to compute a map representation', () {
      final fixedDate = DateTime(2022).toUtc();

      withClock(Clock.fixed(fixedDate), () {
        final matomotoEvent = getCompleteMatomoEvent();
        final eventMap = matomotoEvent.toMap();
        final wantedEvent = getWantedEventMap(fixedDate);

        eventMap.remove('rand');
        wantedEvent.remove('rand');

        expect(mapEquals(wantedEvent, eventMap), true);
      });
    });

    test(
        'it should be able to compute a map representation with User Agent data if tracker have it',
        () {
      when(() => mockMatomoTracker.userAgent)
          .thenReturn(matomoTrackerUserAgent);

      final fixedDate = DateTime(2022).toUtc();

      withClock(Clock.fixed(fixedDate), () {
        final matomotoEvent = getCompleteMatomoEvent();
        final eventMap = matomotoEvent.toMap();
        final wantedEvent =
            getWantedEventMap(fixedDate, userAgent: matomoTrackerUserAgent);

        eventMap.remove('rand');
        wantedEvent.remove('rand');

        expect(mapEquals(wantedEvent, eventMap), true);
      });
    });
  });
}
