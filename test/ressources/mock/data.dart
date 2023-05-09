import 'package:flutter/material.dart';

import 'mock.dart';

// Session
final sessionLastVisite = DateTime(2022, 1, 2).toUtc();
final sessionFirstVisite = DateTime(2022).toUtc();
const sessionVisitCount = 1;

// Visitor
const visitorId = 'visitorId';
const uid = 'userId';

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
Map<String, String> getWantedEventMap(DateTime now, {String? userAgent}) => {
      "idsite": "1",
      "rec": "1",
      "action_name": "action",
      "url": "contentBase/path",
      "_id": "visitorId",
      "apiv": "1",
      "_idvc": "1",
      "_viewts": '${sessionLastVisite.millisecondsSinceEpoch ~/ 1000}',
      "_idts": '${sessionFirstVisite.millisecondsSinceEpoch ~/ 1000}',
      "res": "200x200",
      "h": now.hour.toString(),
      "m": now.minute.toString(),
      "s": now.second.toString(),
      "cookie": "1",
      if (userAgent != null) "ua": userAgent,
      "lang": "en_US",
      "uid": "userId",
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
      "cdt": now.toIso8601String(),
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
const matomoTrackerContentBaseUrl = 'https://example.com';
const matomoTrackerPackageName = 'packageName';
const matomoTrackerWrongVisitorId = '1234'; // not 16 characters
const matomoTrackerEvenName = 'eventName';
const matomoTrackerMockWidget = MockWidget();
const matomoTrackerGoalId = 1;
const matomoTrackerEventCategory = 'eventCategory';
const matomoTrackerAction = 'action';
const matomoTrackerDimensions = <String, String>{};
const matomoTrackerSearchKeyword = 'searchKeyword';
const matomoTrackerVisitorId = '1234567890123456'; // 16 characters
const matomoTrackerUserAgent = 'userAgent';
const matomoTrackerTokenAuth = 'tokenAuth';
final matomoTrackerLocalFirstVisist = DateTime.fromMillisecondsSinceEpoch(
  1640979000000,
  isUtc: true,
);
const matomoTrackerCurrentScreenId = '123456'; // 6 characters

// DeviceInfoPlugin
const webBrowserUserAgent = 'webBrowserUserAgent';
const androidRelease = 'androidRelease';
const androidSdkInt = 1;
const androidManufacturer = 'androidManufacturer';
const androidModel = 'androidModel';
const iosSystemName = 'iosSystemName';
const iosSystemVersion = 'iosSystemVersion';
const iosModel = 'iosModel';
const windowsReleaseId = 'windowsReleaseId';
const windowsBuildNumber = 1;
const macOsModel = 'macOsModel';
const macOsKernelVersion = 'macOsKernelVersion';
const macOsRelease = 'macOsRelease';
const linuxPrettyName = 'linuxPrettyName';
