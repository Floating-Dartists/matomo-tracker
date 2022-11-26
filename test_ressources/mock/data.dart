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
const matomoWrongScreenId = '123';
const matomoSearchCategory = 'searchCategory';
const matomoSearchCount = 1;
const matomoSearchKeyword = 'searchKeyword';
const matomoShippingCost = 1.0;
const matomoSubTotal = 1.0;
const matomoTaxAmount = 1.0;
final matomoTrackingOrderItems = [mockTrackingOrderItem];
final wantedEventMap = {
  "idsite": "1",
  "rec": "1",
  "action_name": "action",
  "url": "contentBase/path",
  "_id": "visitorId",
  "apiv": "1",
  "_idvc": "1",
  "_viewts": "1641078000",
  "_idts": "1640991600",
  "res": "200x200",
  "h": "23",
  "m": "0",
  "s": "0",
  "cookie": "1",
  "lang": "en_US",
  "uid": "userId",
  "cid": "1234567890123456",
  "pv_id": "123456",
  "idgoal": "1",
  "e_c": "eventCategory",
  "e_a": "action",
  "e_n": "eventName",
  "e_v": "1.0",
  "ec_id": "orderId",
  "ec_items": "[[]]",
  "revenue": "1.0",
  "ec_st": "1.0",
  "ec_tx": "1.0",
  "ec_sh": "1.0",
  "ec_dt": "1.0",
  "search": "searchKeyword",
  "search_cat": "searchCategory",
  "search_count": "1",
  "link": "link",
  "cdt": "2021-12-31T23:00:00.000Z",
  "dimension": "dimension"
};

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