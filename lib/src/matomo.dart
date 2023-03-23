import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import 'package:clock/clock.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:matomo_tracker/src/exceptions.dart';
import 'package:matomo_tracker/src/local_storage/local_storage.dart';
import 'package:matomo_tracker/src/local_storage/shared_prefs_storage.dart';
import 'package:matomo_tracker/src/logger.dart';
import 'package:matomo_tracker/src/matomo_dispatcher.dart';
import 'package:matomo_tracker/src/matomo_event.dart';
import 'package:matomo_tracker/src/platform_info/platform_info.dart';
import 'package:matomo_tracker/src/session.dart';
import 'package:matomo_tracker/src/tracking_order_item.dart';
import 'package:matomo_tracker/src/visitor.dart';
import 'package:matomo_tracker/utils/lock.dart' as sync;
import 'package:matomo_tracker/utils/random_alpha_numeric.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

class MatomoTracker {
  /// This is only used for testing purpose, because testing singleton is hard
  @visibleForTesting
  MatomoTracker();

  MatomoTracker._internal();

  final log = Logger('Matomo');
  late final PlatformInfo _platformInfo;

  late MatomoDispatcher _dispatcher;

  static final instance = MatomoTracker._internal();

  late final int siteId;
  late final String url;
  late final Session session;

  Visitor get visitor => _visitor;
  late Visitor _visitor;

  void setVisitorUserId(String? userId) {
    _initializationCheck();

    _visitor = Visitor(
      id: _visitor.id,
      forcedId: _visitor.forcedId,
      userId: userId,
    );
  }

  /// The user agent is used to detect the operating system and browser used.
  late final String? userAgent;

  /// URL for the current action.
  late final String contentBase;

  /// The resolution of the device the visitor is using, eg **1280x1024**.
  late final Size screenResolution;

  /// 6 character unique ID that identifies which actions were performed on a
  /// specific page view.
  String? currentScreenId;

  bool _initialized = false;
  bool get initialized => _initialized;

  bool _optOut = false;
  bool get optOut => _optOut;
  Future<void> setOptOut({required bool optOut}) async {
    _optOut = optOut;
    await _localStorage.setOptOut(optOut: optOut);
  }

  bool _cookieless = false;
  bool get cookieless => _cookieless;

  late final LocalStorage _localStorage;

  @visibleForTesting
  final queue = Queue<MatomoEvent>();

  @visibleForTesting
  late Timer timer;

  late sync.Lock _lock;

  String? _tokenAuth;

  String? get getAuthToken => _tokenAuth;

  int _dequeueInterval = 10;

  /// Initialize the tracker.
  ///
  /// This method must be called before any other method. Otherwise they might
  /// throw an [UninitializedMatomoInstanceException].
  ///
  /// If the tracker is already initialized, an
  /// [AlreadyInitializedMatomoInstanceException] will be thrown.
  ///
  /// The [siteId] should have a length of 16 characters otherwise an
  /// [ArgumentError] will be thrown.
  Future<void> initialize({
    required int siteId,
    required String url,
    String? visitorId,
    String? contentBaseUrl,
    int dequeueInterval = 10,
    String? tokenAuth,
    LocalStorage? localStorage,
    PackageInfo? packageInfo,
    PlatformInfo? platformInfo,
    bool cookieless = false,
  }) async {
    if (_initialized) {
      throw const AlreadyInitializedMatomoInstanceException();
    }

    if (visitorId != null && visitorId.length != 16) {
      throw ArgumentError.value(
        visitorId,
        'visitorId',
        'The visitorId must be 16 characters long',
      );
    }

    this.siteId = siteId;
    this.url = url;
    _dequeueInterval = dequeueInterval;
    _lock = sync.Lock();
    _localStorage = localStorage ?? SharedPrefsStorage();
    _platformInfo = platformInfo ?? PlatformInfo.instance;
    _cookieless = cookieless;

    final localVisitorId = visitorId ??
        await _localStorage.getVisitorId() ??
        const Uuid().v4().replaceAll('-', '').substring(0, 16);
    _visitor = Visitor(id: localVisitorId, userId: localVisitorId);

    _tokenAuth = tokenAuth;
    _dispatcher = MatomoDispatcher(url, tokenAuth);

    // User agent
    userAgent = await getUserAgent();

    // Screen Resolution
    screenResolution = Size(
      window.physicalSize.width,
      window.physicalSize.height,
    );

    // Initialize Session Information
    final now = clock.now().toUtc();
    DateTime firstVisit = now;
    int visitCount = 1;

    final localFirstVisit = await _getFirstVisit();
    if (localFirstVisit != null) {
      firstVisit = localFirstVisit;
    } else {
      unawaited(_saveFirstVisit(now));

      // Save the visitorId for future visits.
      unawaited(_saveVisitorId(localVisitorId));
    }

    final localVisitorCount = await _localStorage.getVisitCount();
    visitCount += localVisitorCount;
    unawaited(_localStorage.setVisitCount(visitCount));

    session = Session(
      firstVisit: firstVisit,
      lastVisit: now,
      visitCount: visitCount,
    );

    if (contentBaseUrl != null) {
      contentBase = contentBaseUrl;
    } else if (kIsWeb) {
      contentBase = Uri.base.toString();
    } else {
      final effectivePackageInfo =
          packageInfo ?? await PackageInfo.fromPlatform();
      contentBase = 'https://${effectivePackageInfo.packageName}';
    }

    _optOut = await _localStorage.getOptOut();
    unawaited(_localStorage.setOptOut(optOut: _optOut));

    log.fine(
      'Matomo Initialized: firstVisit=$firstVisit; lastVisit=$now; visitCount=$visitCount; visitorId=$visitorId; contentBase=$contentBase; resolution=${screenResolution.width}x${screenResolution.height}; userAgent=$userAgent',
    );
    _initialized = true;

    timer = Timer.periodic(Duration(seconds: _dequeueInterval), (_) {
      _dequeue();
    });
  }

  @visibleForTesting
  Future<String?> getUserAgent({
    DeviceInfoPlugin? deviceInfoPlugin,
  }) async {
    try {
      final effectiveDeviceInfo = deviceInfoPlugin ?? DeviceInfoPlugin();
      if (_platformInfo.isWeb) {
        final webBrowserInfo = await effectiveDeviceInfo.webBrowserInfo;

        return webBrowserInfo.userAgent;
      } else if (_platformInfo.isAndroid) {
        final androidInfo = await effectiveDeviceInfo.androidInfo;
        final release = androidInfo.version.release;
        final sdkInt = androidInfo.version.sdkInt;
        final manufacturer = androidInfo.manufacturer;
        final model = androidInfo.model;

        return 'Android $release (SDK $sdkInt), $manufacturer $model';
      } else if (_platformInfo.isIOS) {
        final iosInfo = await effectiveDeviceInfo.iosInfo;
        final systemName = iosInfo.systemName;
        final version = iosInfo.systemVersion;
        final model = iosInfo.model;

        return '$systemName $version, $model';
      } else if (_platformInfo.isWindows) {
        final windowsInfo = await effectiveDeviceInfo.windowsInfo;
        final releaseId = windowsInfo.releaseId;
        final buildNumber = windowsInfo.buildNumber;

        return 'Windows $releaseId.$buildNumber';
      } else if (_platformInfo.isMacOS) {
        final macInfo = await effectiveDeviceInfo.macOsInfo;
        final model = macInfo.model;
        final version = macInfo.kernelVersion;
        final release = macInfo.osRelease;

        return '$model, $version, $release';
      } else if (_platformInfo.isLinux) {
        final linuxInfo = await effectiveDeviceInfo.linuxInfo;

        return linuxInfo.prettyName;
      } else {
        return 'Unknown';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Clear the following data from the local storage:
  ///
  /// - First visit
  /// - Number of visits
  /// - Visitor ID
  void clear() {
    _localStorage.clear();
  }

  /// Cancel the timer which checks the queued events to send. (This will not
  /// clear the queue.)
  void dispose() {
    timer.cancel();
  }

  // Pause tracker
  void pause() {
    timer.cancel();
    _dequeue();
  }

  // Resume tracker
  void resume() {
    if (!timer.isActive) {
      timer = Timer.periodic(Duration(seconds: _dequeueInterval), (timer) {
        _dequeue();
      });
    }
  }

  /// Iterate on the events in the queue and send them to Matomo.
  FutureOr<void> dispatchEvents() {
    return _dequeue();
  }

  /// This will register an event with [trackScreenWithName] by using the
  /// `context.widget.toStringShort()` value.
  ///
  /// - `eventName`: The name of the event.
  ///
  /// - `currentScreenId`: A 6 character unique ID that identifies which actions
  /// were performed on a specific page view. If `null`, a random id will be
  /// generated.
  ///
  /// - `path`: A string that identifies the path of the screen. If not
  /// `null`, it will be combined to [contentBase] to create a URL.
  void trackScreen(
    BuildContext context, {
    required String eventName,
    String? currentScreenId,
    String? path,
    Map<String, String>? dimensions,
  }) {
    if (currentScreenId != null) {
      this.currentScreenId = currentScreenId;
    }
    final widgetName = context.widget.toStringShort();
    trackScreenWithName(
      widgetName: widgetName,
      eventName: eventName,
      currentScreenId: currentScreenId,
      path: path,
      dimensions: dimensions,
    );
  }

  /// Register an event with [eventName] as the event's name and [widgetName] as
  /// the event's action.
  ///
  /// - `widgetName`: Equivalent to the event action, here used to identify the
  /// screen with a proper name.
  ///
  /// - `eventName`: The name of the event.
  ///
  /// - `currentScreenId`: A 6 character unique ID that identifies which actions
  /// were performed on a specific page view. If `null`, a random id will be
  /// generated.
  ///
  /// - `path`: A string that identifies the path of the screen. If not
  /// `null`, it will be combined to [contentBase] to create a URL.
  void trackScreenWithName({
    required String widgetName,
    required String eventName,
    String? currentScreenId,
    String? path,
    Map<String, String>? dimensions,
  }) {
    _initializationCheck();

    if (currentScreenId != null && currentScreenId.length != 6) {
      throw ArgumentError.value(
        currentScreenId,
        'currentScreenId',
        'The currentScreenId must be 6 characters long.',
      );
    }

    this.currentScreenId = currentScreenId ?? randomAlphaNumeric(6);
    return _track(
      MatomoEvent(
        tracker: this,
        eventName: eventName,
        action: widgetName,
        path: path,
        dimensions: dimensions,
      ),
    );
  }

  void trackGoal(
    int goalId, {
    double? revenue,
    Map<String, String>? dimensions,
  }) {
    _initializationCheck();

    return _track(
      MatomoEvent(
        tracker: this,
        goalId: goalId,
        revenue: revenue,
        dimensions: dimensions,
      ),
    );
  }

  void trackEvent({
    required String eventCategory,
    required String action,
    String? eventName,
    int? eventValue,
    Map<String, String>? dimensions,
  }) {
    return _track(
      MatomoEvent(
        tracker: this,
        action: action,
        eventAction: action,
        eventName: eventName,
        eventCategory: eventCategory,
        eventValue: eventValue,
        dimensions: dimensions,
      ),
    );
  }

  void trackDimensions(Map<String, String> dimensions) {
    return _track(
      MatomoEvent(
        tracker: this,
        dimensions: dimensions,
      ),
    );
  }

  void trackSearch({
    required String searchKeyword,
    String? searchCategory,
    int? searchCount,
    Map<String, String>? dimensions,
  }) {
    return _track(
      MatomoEvent(
        tracker: this,
        searchKeyword: searchKeyword,
        searchCategory: searchCategory,
        searchCount: searchCount,
        dimensions: dimensions,
      ),
    );
  }

  void trackCartUpdate(
    List<TrackingOrderItem>? trackingOrderItems,
    num? subTotal,
    num? taxAmount,
    num? shippingCost,
    num? discountAmount, {
    Map<String, String>? dimensions,
  }) {
    _initializationCheck();

    return _track(
      MatomoEvent(
        tracker: this,
        goalId: 0,
        trackingOrderItems: trackingOrderItems,
        subTotal: subTotal,
        taxAmount: taxAmount,
        shippingCost: shippingCost,
        discountAmount: discountAmount,
        dimensions: dimensions,
      ),
    );
  }

  void trackOrder(
    String? orderId,
    List<TrackingOrderItem>? trackingOrderItems,
    num? revenue,
    num? subTotal,
    num? taxAmount,
    num? shippingCost,
    num? discountAmount, {
    Map<String, String>? dimensions,
  }) {
    _initializationCheck();

    return _track(
      MatomoEvent(
        tracker: this,
        goalId: 0,
        orderId: orderId,
        trackingOrderItems: trackingOrderItems,
        revenue: revenue,
        subTotal: subTotal,
        taxAmount: taxAmount,
        shippingCost: shippingCost,
        discountAmount: discountAmount,
        dimensions: dimensions,
      ),
    );
  }

  void trackOutlink(
    String? link, {
    Map<String, String>? dimensions,
  }) {
    _initializationCheck();

    return _track(
      MatomoEvent(
        tracker: this,
        link: link,
        dimensions: dimensions,
      ),
    );
  }

  void _track(MatomoEvent event) {
    queue.add(event);
  }

  FutureOr<void> _dequeue() {
    if (!_initialized) {
      throw const UninitializedMatomoInstanceException();
    }

    log.finest('Processing queue ${queue.length}');

    if (!_lock.locked) {
      return _lock.synchronized(() async {
        final events = List<MatomoEvent>.from(queue);
        if (!_optOut) {
          final hasSucceeded = await _dispatcher.sendBatch(events);
          if (hasSucceeded) {
            // As the operation is asynchronous we need to be sure to remove
            // only the events that were sent in the batch.
            queue.removeWhere(events.contains);
          }
        }
      });
    }
  }

  void _initializationCheck() {
    if (!_initialized) {
      throw const UninitializedMatomoInstanceException();
    }
  }

  Future<void> _saveFirstVisit(DateTime firstVisit) async {
    if (_cookieless) return;

    await _localStorage.setFirstVisit(firstVisit);
  }

  Future<DateTime?> _getFirstVisit() async {
    if (_cookieless) return null;

    return _localStorage.getFirstVisit();
  }

  Future<void> _saveVisitorId(String visitorId) async {
    if (_cookieless) return;

    await _localStorage.setVisitorId(visitorId);
  }
}
