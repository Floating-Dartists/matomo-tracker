import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/src/campaign.dart';
import 'package:matomo_tracker/src/content.dart';
import 'package:matomo_tracker/src/event_info.dart';
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
      dimensions: matomoEventDimension,
      discountAmount: matomoDiscountAmount,
      eventInfo: EventInfo(
        category: matomoEventCategory,
        action: matomoEventAction,
        name: matomoEventName,
        value: matomoEventValue,
      ),
      campaign: Campaign(
        name: matomoCampaignName,
        keyword: matomoCampaignKeyword,
        source: matomoCampaignSource,
        medium: matomoCampaignMedium,
        content: matomoCampaignContent,
        id: matomoCampaignId,
        group: matomoCampaignGroup,
        placement: matomoCampaignPlacement,
      ),
      content: Content(
        name: matomoContentName,
        piece: matomoContentPiece,
        target: matomoContentTarget,
      ),
      contentInteraction: matomoContentInteraction,
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
      newVisit: matomoNewVisit,
      ping: matomoPing,
    );
  }

  test('it should be able to create MatomotoEvent', () async {
    final matomotoEvent = getCompleteMatomoEvent();

    expect(matomotoEvent.tracker, mockMatomoTracker);
    expect(matomotoEvent.path, matomoEventPath);
    expect(matomotoEvent.action, matomoEventAction);
    expect(matomotoEvent.eventInfo?.category, matomoEventCategory);
    expect(matomotoEvent.dimensions, matomoEventDimension);
    expect(matomotoEvent.discountAmount, matomoDiscountAmount);
    expect(matomotoEvent.eventInfo?.action, matomoEventAction);
    expect(matomotoEvent.eventInfo?.value, matomoEventValue);
    expect(matomotoEvent.eventInfo?.name, matomoEventName);
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
    expect(matomotoEvent.newVisit, matomoNewVisit);
    expect(matomotoEvent.content?.name, matomoContentName);
    expect(matomotoEvent.content?.piece, matomoContentPiece);
    expect(matomotoEvent.content?.target, matomoContentTarget);
    expect(matomotoEvent.contentInteraction, matomoContentInteraction);
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
        'it should throw ArgumentError if event category is empty',
        () {
          MatomoEvent getMatomoEventWithEmptyEventCategory() {
            return MatomoEvent(
              tracker: mockMatomoTracker,
              eventInfo: EventInfo(
                category: '',
                action: matomoEventAction,
              ),
            );
          }

          expect(
            getMatomoEventWithEmptyEventCategory,
            throwsArgumentError,
          );
        },
      );

      test(
        'it should throw ArgumentError if event action is empty',
        () {
          MatomoEvent getMatomoEventWithEmptyEventAction() {
            return MatomoEvent(
              tracker: mockMatomoTracker,
              eventInfo: EventInfo(
                category: matomoEventCategory,
                action: '',
              ),
            );
          }

          expect(
            getMatomoEventWithEmptyEventAction,
            throwsArgumentError,
          );
        },
      );

      test('it should throw ArgumentError if event name is empty', () {
        MatomoEvent getMatomoEventWithEmptyEventName() {
          return MatomoEvent(
            tracker: mockMatomoTracker,
            eventInfo: EventInfo(
              category: matomoEventCategory,
              action: matomoEventAction,
              name: '',
            ),
          );
        }

        expect(
          getMatomoEventWithEmptyEventName,
          throwsArgumentError,
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
      when(() => mockVisitor.uid).thenReturn(uid);
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

        expect(mapEquals(wantedEvent, eventMap), isTrue);
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

        expect(mapEquals(wantedEvent, eventMap), isTrue);
      });
    });
  });

  group('copyWith', () {
    setUpAll(() {
      when(() => mockMatomoTracker.visitor).thenReturn(mockVisitor);
      when(() => mockMatomoTracker.session).thenReturn(mockSession);
      when(() => mockMatomoTracker.screenResolution)
          .thenReturn(matomoTrackerScreenResolution);
      when(() => mockMatomoTracker.contentBase)
          .thenReturn(matomoTrackerContentBase);
      when(() => mockMatomoTracker.siteId).thenReturn(matomoTrackerSiteId);
      when(() => mockVisitor.id).thenReturn(visitorId);
      when(() => mockVisitor.uid).thenReturn(uid);
      when(mockTrackingOrderItem.toArray).thenReturn([]);
      when(() => mockSession.visitCount).thenReturn(sessionVisitCount);
      when(() => mockSession.lastVisit).thenReturn(sessionLastVisite);
      when(() => mockSession.firstVisit).thenReturn(sessionFirstVisite);
    });

    test('it should be able to create a unchanged copy', () {
      final fixedDate = DateTime(2022).toUtc();

      withClock(Clock.fixed(fixedDate), () {
        final matomotoEvent = getCompleteMatomoEvent();
        final unchangedCopy = matomotoEvent.copyWith();

        expect(matomotoEvent.tracker, unchangedCopy.tracker);
        expect(matomotoEvent.path, unchangedCopy.path);
        expect(matomotoEvent.action, unchangedCopy.action);
        expect(
          matomotoEvent.eventInfo?.category,
          unchangedCopy.eventInfo?.category,
        );
        expect(matomotoEvent.dimensions, unchangedCopy.dimensions);
        expect(matomotoEvent.discountAmount, unchangedCopy.discountAmount);
        expect(
          matomotoEvent.eventInfo?.action,
          unchangedCopy.eventInfo?.action,
        );
        expect(matomotoEvent.eventInfo?.value, unchangedCopy.eventInfo?.value);
        expect(matomotoEvent.eventInfo?.name, unchangedCopy.eventInfo?.name);
        expect(matomotoEvent.goalId, unchangedCopy.goalId);
        expect(matomotoEvent.link, unchangedCopy.link);
        expect(matomotoEvent.orderId, unchangedCopy.orderId);
        expect(matomotoEvent.revenue, unchangedCopy.revenue);
        expect(matomotoEvent.screenId, unchangedCopy.screenId);
        expect(matomotoEvent.searchCategory, unchangedCopy.searchCategory);
        expect(matomotoEvent.searchCount, unchangedCopy.searchCount);
        expect(matomotoEvent.searchKeyword, unchangedCopy.searchKeyword);
        expect(matomotoEvent.shippingCost, unchangedCopy.shippingCost);
        expect(matomotoEvent.subTotal, unchangedCopy.subTotal);
        expect(matomotoEvent.taxAmount, unchangedCopy.taxAmount);
        expect(
          matomotoEvent.trackingOrderItems,
          unchangedCopy.trackingOrderItems,
        );
        expect(matomotoEvent.newVisit, unchangedCopy.newVisit);
        expect(matomotoEvent.ping, unchangedCopy.ping);
        expect(
          matomotoEvent.content?.name,
          unchangedCopy.content?.name,
        );
        expect(matomotoEvent.content?.piece, unchangedCopy.content?.piece);
        expect(matomotoEvent.content?.target, unchangedCopy.content?.target);
        expect(
            matomotoEvent.contentInteraction, unchangedCopy.contentInteraction);
      });
    });

    test('it should be able to create a changed copy', () {
      final fixedDate = DateTime(2022).toUtc();

      withClock(Clock.fixed(fixedDate), () {
        final matomotoEvent = getCompleteMatomoEvent();
        final changedCopy =
            matomotoEvent.copyWith(newVisit: matomoChangedNewVisit);

        expect(matomotoEvent.tracker, changedCopy.tracker);
        expect(matomotoEvent.path, changedCopy.path);
        expect(matomotoEvent.action, changedCopy.action);
        expect(
          matomotoEvent.eventInfo?.category,
          changedCopy.eventInfo?.category,
        );
        expect(matomotoEvent.dimensions, changedCopy.dimensions);
        expect(matomotoEvent.discountAmount, changedCopy.discountAmount);
        expect(
          matomotoEvent.eventInfo?.action,
          changedCopy.eventInfo?.action,
        );
        expect(matomotoEvent.eventInfo?.value, changedCopy.eventInfo?.value);
        expect(matomotoEvent.eventInfo?.name, changedCopy.eventInfo?.name);
        expect(matomotoEvent.goalId, changedCopy.goalId);
        expect(matomotoEvent.link, changedCopy.link);
        expect(matomotoEvent.orderId, changedCopy.orderId);
        expect(matomotoEvent.revenue, changedCopy.revenue);
        expect(matomotoEvent.screenId, changedCopy.screenId);
        expect(matomotoEvent.searchCategory, changedCopy.searchCategory);
        expect(matomotoEvent.searchCount, changedCopy.searchCount);
        expect(matomotoEvent.searchKeyword, changedCopy.searchKeyword);
        expect(matomotoEvent.shippingCost, changedCopy.shippingCost);
        expect(matomotoEvent.subTotal, changedCopy.subTotal);
        expect(matomotoEvent.taxAmount, changedCopy.taxAmount);
        expect(
          matomotoEvent.trackingOrderItems,
          changedCopy.trackingOrderItems,
        );
        expect(matomoChangedNewVisit, changedCopy.newVisit);
        expect(matomotoEvent.ping, changedCopy.ping);
        expect(
          matomotoEvent.content?.name,
          changedCopy.content?.name,
        );
        expect(matomotoEvent.content?.piece, changedCopy.content?.piece);
        expect(matomotoEvent.content?.target, changedCopy.content?.target);
        expect(
            matomotoEvent.contentInteraction, changedCopy.contentInteraction);
      });
    });
  });
}
