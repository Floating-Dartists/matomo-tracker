import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/src/campaign.dart';
import 'package:matomo_tracker/src/content.dart';
import 'package:matomo_tracker/src/event_info.dart';
import 'package:matomo_tracker/src/matomo_action.dart';
import 'package:matomo_tracker/src/performance_info.dart';
import 'package:mocktail/mocktail.dart';

import '../ressources/mock/data.dart';
import '../ressources/mock/mock.dart';

void main() {
  MatomoAction getCompleteMatomoAction() {
    return MatomoAction(
      path: matomoActionPath,
      action: matomoActionName,
      dimensions: matomoEventDimension,
      discountAmount: matomoDiscountAmount,
      eventInfo: EventInfo(
        category: matomoEventCategory,
        action: matomoActionName,
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
      pvId: matomoPvId,
      searchCategory: matomoSearchCategory,
      searchCount: matomoSearchCount,
      searchKeyword: matomoSearchKeyword,
      shippingCost: matomoShippingCost,
      subTotal: matomoSubTotal,
      taxAmount: matomoTaxAmount,
      trackingOrderItems: matomoTrackingOrderItems,
      newVisit: matomoNewVisit,
      ping: matomoPing,
      performanceInfo: PerformanceInfo(
        networkTime: matomoPerformanceInfoNetworkTime,
        serverTime: matomoPerformanceInfoServerTime,
        transferTime: matomoPerformanceInfoTransferTime,
        domProcessingTime: matomoPerformanceInfoDomProcessingTime,
        domCompletionTime: matomoPerformanceInfoDomCompletionTime,
        onloadTime: matomoPerformanceInfoOnloadTime,
      ),
    );
  }

  test('it should be able to create MatomoAction', () async {
    final matomoAction = getCompleteMatomoAction();

    expect(matomoAction.path, matomoActionPath);
    expect(matomoAction.action, matomoActionName);
    expect(matomoAction.eventInfo?.category, matomoEventCategory);
    expect(matomoAction.dimensions, matomoEventDimension);
    expect(matomoAction.discountAmount, matomoDiscountAmount);
    expect(matomoAction.eventInfo?.action, matomoActionName);
    expect(matomoAction.eventInfo?.value, matomoEventValue);
    expect(matomoAction.eventInfo?.name, matomoEventName);
    expect(matomoAction.goalId, matomoGoalId);
    expect(matomoAction.link, matomoLink);
    expect(matomoAction.orderId, matomoOrderId);
    expect(matomoAction.revenue, matomoRevenue);
    expect(matomoAction.pvId, matomoPvId);
    expect(matomoAction.searchCategory, matomoSearchCategory);
    expect(matomoAction.searchCount, matomoSearchCount);
    expect(matomoAction.searchKeyword, matomoSearchKeyword);
    expect(matomoAction.shippingCost, matomoShippingCost);
    expect(matomoAction.subTotal, matomoSubTotal);
    expect(matomoAction.taxAmount, matomoTaxAmount);
    expect(matomoAction.trackingOrderItems, matomoTrackingOrderItems);
    expect(matomoAction.newVisit, matomoNewVisit);
    expect(matomoAction.content?.name, matomoContentName);
    expect(matomoAction.content?.piece, matomoContentPiece);
    expect(matomoAction.content?.target, matomoContentTarget);
    expect(matomoAction.contentInteraction, matomoContentInteraction);
    expect(
      matomoAction.performanceInfo?.networkTime,
      matomoPerformanceInfoNetworkTime,
    );
    expect(
      matomoAction.performanceInfo?.serverTime,
      matomoPerformanceInfoServerTime,
    );
    expect(
      matomoAction.performanceInfo?.transferTime,
      matomoPerformanceInfoTransferTime,
    );
    expect(
      matomoAction.performanceInfo?.domProcessingTime,
      matomoPerformanceInfoDomProcessingTime,
    );
    expect(
      matomoAction.performanceInfo?.domCompletionTime,
      matomoPerformanceInfoDomCompletionTime,
    );
    expect(
      matomoAction.performanceInfo?.onloadTime,
      matomoPerformanceInfoOnloadTime,
    );
  });

  group(
    'AssertionError checking',
    () {
      test(
        'it should throw AssertionError if screen id is not 6 characters',
        () {
          MatomoAction getMatomoActionWithWrongPvId() {
            return MatomoAction(
              pvId: matomoWrongPvId,
            );
          }

          expect(
            getMatomoActionWithWrongPvId,
            throwsAssertionError,
          );
        },
      );

      test(
        'it should throw ArgumentError if event category is empty',
        () {
          MatomoAction getMatomoActionWithEmptyEventCategory() {
            return MatomoAction(
              eventInfo: EventInfo(
                category: '',
                action: matomoActionName,
              ),
            );
          }

          expect(
            getMatomoActionWithEmptyEventCategory,
            throwsArgumentError,
          );
        },
      );

      test(
        'it should throw ArgumentError if event action is empty',
        () {
          MatomoAction getMatomoActionWithEmptyEventAction() {
            return MatomoAction(
              eventInfo: EventInfo(
                category: matomoEventCategory,
                action: '',
              ),
            );
          }

          expect(
            getMatomoActionWithEmptyEventAction,
            throwsArgumentError,
          );
        },
      );

      test('it should throw ArgumentError if event name is empty', () {
        MatomoAction getMatomoActionWithEmptyEventName() {
          return MatomoAction(
            eventInfo: EventInfo(
              category: matomoEventCategory,
              action: matomoActionName,
              name: '',
            ),
          );
        }

        expect(
          getMatomoActionWithEmptyEventName,
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
        final matomoAction = getCompleteMatomoAction();
        final eventMap = matomoAction.toMap(mockMatomoTracker);
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
        final matomoAction = getCompleteMatomoAction();
        final eventMap = matomoAction.toMap(mockMatomoTracker);
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
        final matomoAction = getCompleteMatomoAction();
        final unchangedCopy = matomoAction.copyWith();

        expect(matomoAction.path, unchangedCopy.path);
        expect(matomoAction.action, unchangedCopy.action);
        expect(
          matomoAction.eventInfo?.category,
          unchangedCopy.eventInfo?.category,
        );
        expect(matomoAction.dimensions, unchangedCopy.dimensions);
        expect(matomoAction.discountAmount, unchangedCopy.discountAmount);
        expect(
          matomoAction.eventInfo?.action,
          unchangedCopy.eventInfo?.action,
        );
        expect(matomoAction.eventInfo?.value, unchangedCopy.eventInfo?.value);
        expect(matomoAction.eventInfo?.name, unchangedCopy.eventInfo?.name);
        expect(matomoAction.goalId, unchangedCopy.goalId);
        expect(matomoAction.link, unchangedCopy.link);
        expect(matomoAction.orderId, unchangedCopy.orderId);
        expect(matomoAction.revenue, unchangedCopy.revenue);
        expect(matomoAction.pvId, unchangedCopy.pvId);
        expect(matomoAction.searchCategory, unchangedCopy.searchCategory);
        expect(matomoAction.searchCount, unchangedCopy.searchCount);
        expect(matomoAction.searchKeyword, unchangedCopy.searchKeyword);
        expect(matomoAction.shippingCost, unchangedCopy.shippingCost);
        expect(matomoAction.subTotal, unchangedCopy.subTotal);
        expect(matomoAction.taxAmount, unchangedCopy.taxAmount);
        expect(
          matomoAction.trackingOrderItems,
          unchangedCopy.trackingOrderItems,
        );
        expect(matomoAction.newVisit, unchangedCopy.newVisit);
        expect(matomoAction.ping, unchangedCopy.ping);
        expect(
          matomoAction.content?.name,
          unchangedCopy.content?.name,
        );
        expect(matomoAction.content?.piece, unchangedCopy.content?.piece);
        expect(matomoAction.content?.target, unchangedCopy.content?.target);
        expect(
          matomoAction.contentInteraction,
          unchangedCopy.contentInteraction,
        );
        expect(
          matomoAction.performanceInfo?.networkTime,
          unchangedCopy.performanceInfo?.networkTime,
        );
        expect(
          matomoAction.performanceInfo?.serverTime,
          unchangedCopy.performanceInfo?.serverTime,
        );
        expect(
          matomoAction.performanceInfo?.transferTime,
          unchangedCopy.performanceInfo?.transferTime,
        );
        expect(
          matomoAction.performanceInfo?.domProcessingTime,
          unchangedCopy.performanceInfo?.domProcessingTime,
        );
        expect(
          matomoAction.performanceInfo?.domCompletionTime,
          unchangedCopy.performanceInfo?.domCompletionTime,
        );
        expect(
          matomoAction.performanceInfo?.onloadTime,
          unchangedCopy.performanceInfo?.onloadTime,
        );
      });
    });

    test('it should be able to create a changed copy', () {
      final fixedDate = DateTime(2022).toUtc();

      withClock(Clock.fixed(fixedDate), () {
        final matomoAction = getCompleteMatomoAction();
        final changedCopy =
            matomoAction.copyWith(newVisit: matomoChangedNewVisit);

        expect(matomoAction.path, changedCopy.path);
        expect(matomoAction.action, changedCopy.action);
        expect(
          matomoAction.eventInfo?.category,
          changedCopy.eventInfo?.category,
        );
        expect(matomoAction.dimensions, changedCopy.dimensions);
        expect(matomoAction.discountAmount, changedCopy.discountAmount);
        expect(
          matomoAction.eventInfo?.action,
          changedCopy.eventInfo?.action,
        );
        expect(matomoAction.eventInfo?.value, changedCopy.eventInfo?.value);
        expect(matomoAction.eventInfo?.name, changedCopy.eventInfo?.name);
        expect(matomoAction.goalId, changedCopy.goalId);
        expect(matomoAction.link, changedCopy.link);
        expect(matomoAction.orderId, changedCopy.orderId);
        expect(matomoAction.revenue, changedCopy.revenue);
        expect(matomoAction.pvId, changedCopy.pvId);
        expect(matomoAction.searchCategory, changedCopy.searchCategory);
        expect(matomoAction.searchCount, changedCopy.searchCount);
        expect(matomoAction.searchKeyword, changedCopy.searchKeyword);
        expect(matomoAction.shippingCost, changedCopy.shippingCost);
        expect(matomoAction.subTotal, changedCopy.subTotal);
        expect(matomoAction.taxAmount, changedCopy.taxAmount);
        expect(
          matomoAction.trackingOrderItems,
          changedCopy.trackingOrderItems,
        );
        expect(matomoChangedNewVisit, changedCopy.newVisit);
        expect(matomoAction.ping, changedCopy.ping);
        expect(
          matomoAction.content?.name,
          changedCopy.content?.name,
        );
        expect(matomoAction.content?.piece, changedCopy.content?.piece);
        expect(matomoAction.content?.target, changedCopy.content?.target);
        expect(
          matomoAction.contentInteraction,
          changedCopy.contentInteraction,
        );
        expect(
          matomoAction.performanceInfo?.networkTime,
          changedCopy.performanceInfo?.networkTime,
        );
        expect(
          matomoAction.performanceInfo?.serverTime,
          changedCopy.performanceInfo?.serverTime,
        );
        expect(
          matomoAction.performanceInfo?.transferTime,
          changedCopy.performanceInfo?.transferTime,
        );
        expect(
          matomoAction.performanceInfo?.domProcessingTime,
          changedCopy.performanceInfo?.domProcessingTime,
        );
        expect(
          matomoAction.performanceInfo?.domCompletionTime,
          changedCopy.performanceInfo?.domCompletionTime,
        );
        expect(
          matomoAction.performanceInfo?.onloadTime,
          changedCopy.performanceInfo?.onloadTime,
        );
      });
    });
  });
  group('ca', () {
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

    test('it should have ca if its an event or content and not a ping',
        () async {
      final matomoMap = getCompleteMatomoAction().toMap(mockMatomoTracker);

      expect(matomoMap['ca'], '1');
    });

    test('it should not have ca if its a ping', () async {
      final matomoMap = getCompleteMatomoAction()
          .copyWith(
            ping: true,
          )
          .toMap(mockMatomoTracker);

      expect(matomoMap.containsKey('ca'), false);
    });

    test('it should not have performanceInfo if its a ping', () async {
      final matomoMap = getCompleteMatomoAction()
          .copyWith(
            ping: true,
          )
          .toMap(mockMatomoTracker);

      expect(matomoMap.containsKey('pf_net'), false);
      expect(matomoMap.containsKey('pf_srv'), false);
      expect(matomoMap.containsKey('pf_tfr'), false);
      expect(matomoMap.containsKey('pf_dm1'), false);
      expect(matomoMap.containsKey('pf_dm2'), false);
      expect(matomoMap.containsKey('pf_onl'), false);
    });
  });
}
