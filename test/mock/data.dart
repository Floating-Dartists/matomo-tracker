import 'package:flutter/material.dart';

import 'mock.dart';

// Session
final sessionLastVisite = DateTime(2022, 1, 2);
final sessionFirstVisite = DateTime(2022, 1, 1);
const sessionVisitCount = 1;

// Visitor
const visitorId = 'visitorId';
const forceId = '1234567890123456'; // 16 characters
const wrongForceId = '1234';
const userId = 'userId';

// TrackingOrderItem
const trackingOrderItemSku = 'skusku';
const trackingOrderItemName = 'name';
const trackingOrderItemCategory = 'category';
const trackingOrderItemPrice = 1.0;
const trackingOrderItemQuantity = 1;

// MatomoEvent
const matomoEventPath = 'path';
const matomoEventAction = 'action';
const matomoEventCategory = 'eventCategory';
const matomoEventDimension = {'dimension': 'dimension'};
const matomoDiscountAmount = 1.0;
const matomoEventValue = 1.0;
const matomoEventName = 'eventName';
const matomoGoalId = 1;
const matomoLink = 'link';
const matomoOrderId = 'orderId';
const matomoRevenue = 1.0;
const matomoScreenId = '123456'; // 6 characters
const matomoWrongScreenId = '123'; // 6 characters
const matomoSearchCategory = 'searchCategory';
const matomoSearchCount = 1;
const matomoSearchKeyword = 'searchKeyword';
const matomoShippingCost = 1.0;
const matomoSubTotal = 1.0;
const matomoTaxAmount = 1.0;
final matomoTrackingOrderItems = [mockTrackingOrderItem];

// MatomoDisptacher
const matomoDispatcherBaseUrl = 'https://example.com';
const matomoDispatcherToken = 'token';

// MatomoTracker
const matomoTrackerContentBase = 'contentBase';
const matomoTrackerSiteId = 1;
const matomoTrackerScreenResolution = Size(200, 200);
const matomoTrackerUrl = 'https://example.com';
const matomoTrackerPackageName = 'packageName';
const matomoTrackerWrongVisitorId = '1234'; // not 16 characters
const matomoTrackerEvenName = 'eventName';
const matomoTrackerMockWidget = MockWidget();
const matomoTrackerGoalId = 1;
const matomoTrackerEventCategory = 'eventCategory';
const matomoTrackerAction = 'action';
const matomoTrackerDimensions = <String, String>{};
const matomoTrackerSearchKeyword = 'searchKeyword';
const matomoTrackerVisiterId = '1234567890123456'; // 16 characters

// Mocks
final mockMatomoTracker = MockMatomoTracker();
final mockTrackingOrderItem = MockTrackingOrderItem();
final mockHttpClient = MockHttpClient();
final mockMatomoEvent = MockMatomoEvent();
final mockHttpResponse = MockHttpResponse();
final mockVisitor = MockVisitor();
final mockSession = MockSession();
final mockSharedPreferences = MockSharedPreferences();
final mockPackageInfo = MockPackageInfo();
final mockBuildContext = MockBuildContext();
