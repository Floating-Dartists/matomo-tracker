import 'dart:async';
import 'dart:collection';

import 'package:clock/clock.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:matomo_tracker/src/campaign.dart';
import 'package:matomo_tracker/src/event_info.dart';
import 'package:matomo_tracker/src/exceptions.dart';
import 'package:matomo_tracker/src/local_storage/cookieless_storage.dart';
import 'package:matomo_tracker/src/local_storage/local_storage.dart';
import 'package:matomo_tracker/src/local_storage/shared_prefs_storage.dart';
import 'package:matomo_tracker/src/logger/log_record.dart';
import 'package:matomo_tracker/src/logger/logger.dart';
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

/// Implementation of the Matomo [Tracking HTTP API](https://developer.matomo.org/api-reference/tracking-api).
///
/// If this documentation refers to a correspondence with a parameter, check out
/// the [Tracking HTTP API](https://developer.matomo.org/api-reference/tracking-api)
/// documentation for more information on that parameter.
class MatomoTracker {
  /// This is only used for testing purpose, because testing singleton is hard.
  @visibleForTesting
  MatomoTracker();

  MatomoTracker._internal();

  final log = Logger('Matomo');

  late final PlatformInfo _platformInfo;

  late MatomoDispatcher _dispatcher;

  static final instance = MatomoTracker._internal();

  /// The ID of the website we're tracking a visit/action for.
  ///
  /// Corresponds with `idsite`.
  late final int siteId;

  /// The url of the Matomo endpoint.
  ///
  /// E.g.: `https://example.com/matomo.php`
  ///
  /// Should not be confused with the `url` tracking parameter
  /// which is constructed by combining [contentBase] with a `path`
  /// (e.g. in [trackScreenWithName]).
  late final String url;
  late final Session session;

  Visitor get visitor => _visitor;
  late Visitor _visitor;

  /// Sets the [User ID](https://matomo.org/guide/reports/user-ids/).
  ///
  /// This should not be confused with the [visitorId] of the [initialize]
  /// call (which corresponds with the `_id` parameter).
  void setVisitorUserId(String? uid) {
    _initializationCheck();

    _visitor = Visitor(
      id: _visitor.id,
      uid: uid,
    );
  }

  /// The user agent is used to detect the operating system and browser used.
  late final String? userAgent;

  /// Custom http headers to add to each request.
  late final Map<String, String> customHeaders;

  /// URL for the current action.
  ///
  /// For the tracking of screens (e.g. with [trackScreenWithName]) this is combined
  /// with the `path` parameter to create the tracked `url`.
  late final String contentBase;

  /// The resolution of the device the visitor is using, eg **1280x1024**.
  late final Size screenResolution;

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

  late final int _dequeueInterval;

  late bool _newVisit;

  /// Initialize the tracker.
  ///
  /// This method must be called before any other method. Otherwise they might
  /// throw an [UninitializedMatomoInstanceException].
  ///
  /// If the tracker is already initialized, an
  /// [AlreadyInitializedMatomoInstanceException] will be thrown.
  ///
  /// The [newVisit] parameter is used to mark this initialization the start
  /// of a new visit. If set to `false` it is left to Matomo to decide if this
  /// is a new visit or not.
  ///
  /// The [visitorId] should have a length of 16 characters otherwise an
  /// [ArgumentError] will be thrown. This parameter corresponds with the
  /// `_id` and should not be confused with the user id `uid`.
  ///
  /// If [cookieless] is set to true, a [CookielessStorage] instance will be
  /// used. This means that the first_visit and the user_id will be stored in
  /// memory and will be lost when the app is closed.
  Future<void> initialize({
    required int siteId,
    required String url,
    bool newVisit = true,
    String? visitorId,
    String? uid,
    String? contentBaseUrl,
    int dequeueInterval = 10,
    String? tokenAuth,
    LocalStorage? localStorage,
    PackageInfo? packageInfo,
    PlatformInfo? platformInfo,
    bool cookieless = false,
    Level verbosityLevel = Level.off,
    Map<String, String> customHeaders = const {},
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

    log.setLogging(level: verbosityLevel);

    this.siteId = siteId;
    this.url = url;
    this.customHeaders = customHeaders;
    _dequeueInterval = dequeueInterval;
    _lock = sync.Lock();
    _platformInfo = platformInfo ?? PlatformInfo.instance;
    _cookieless = cookieless;
    _tokenAuth = tokenAuth;
    _dispatcher = MatomoDispatcher(url, tokenAuth);
    _newVisit = newVisit;

    final effectiveLocalStorage = localStorage ?? SharedPrefsStorage();
    _localStorage = cookieless
        ? CookielessStorage(storage: effectiveLocalStorage)
        : effectiveLocalStorage;

    final localVisitorId = visitorId ?? await _getVisitorId();
    _visitor = Visitor(id: localVisitorId, uid: uid);

    // User agent
    userAgent = await getUserAgent();

    // Screen Resolution
    final physicalSize = PlatformDispatcher.instance.views.first.physicalSize;
    screenResolution = Size(
      physicalSize.width,
      physicalSize.height,
    );

    // Initialize Session Information
    final now = clock.now().toUtc();
    DateTime firstVisit = now;
    int visitCount = 1;

    final localFirstVisit = await _localStorage.getFirstVisit();
    if (localFirstVisit != null) {
      firstVisit = localFirstVisit;
    } else {
      unawaited(_localStorage.setFirstVisit(now));

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

  /// {@macro local_storage.clear}
  void clear() => _localStorage.clear();

  /// Cancel the timer which checks the queued events to send. (This will not
  /// clear the queue.)
  void dispose() {
    timer.cancel();
    log.clearListeners();
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

  /// This will register a page view with [trackScreenWithName] by using the
  /// `context.widget.toStringShort()` as `actionName` value.
  ///
  /// - `pvId`: A 6 character unique ID that identifies which actions
  /// were performed on a specific page view. If `null`, a random id will be
  /// generated.
  ///
  /// - `path`: A string that identifies the path of the screen. If not
  /// `null`, it will be combined to [contentBase] to create a URL. This combination
  /// corresponds with `url`.
  ///
  /// - `campaign`: The campaign that lead to this page view.
  ///
  /// For remarks on [dimensions] see [trackDimensions].
  void trackScreen(
    BuildContext context, {
    String? pvId,
    String? path,
    Campaign? campaign,
    Map<String, String>? dimensions,
  }) {
    final actionName = context.widget.toStringShort();

    trackScreenWithName(
      actionName: actionName,
      pvId: pvId,
      path: path,
      campaign: campaign,
      dimensions: dimensions,
    );
  }

  /// Registers a page view.
  ///
  /// - `actionName`: Equivalent to the page name, here used to identify the
  /// screen with a proper name.
  ///
  /// - `pvId`: A 6 character unique ID that identifies which actions
  /// were performed on a specific page view. If `null`, a random ID will be
  /// generated.
  ///
  /// - `path`: A string that identifies the path of the screen. If not
  /// `null`, it will be combined to [contentBase] to create a URL. This
  /// combination corresponds with `url`.
  ///
  /// - `campaign`: The campaign that lead to this page view.
  ///
  /// For remarks on [dimensions] see [trackDimensions].
  void trackScreenWithName({
    required String actionName,
    String? pvId,
    String? path,
    Campaign? campaign,
    Map<String, String>? dimensions,
  }) {
    _initializationCheck();

    if (pvId != null && pvId.length != 6) {
      throw ArgumentError.value(
        pvId,
        'pvId',
        'The pvId must be 6 characters long.',
      );
    }

    validateDimension(dimensions);
    return _track(
      MatomoEvent(
        tracker: this,
        action: actionName,
        path: path,
        campaign: campaign,
        dimensions: dimensions,
        screenId: pvId ?? randomAlphaNumeric(6),
      ),
    );
  }

  /// Tracks a conversion for a goal.
  ///
  /// The [goalId] corresponds with `idgoal` and [revenue] with `revenue`.
  ///
  /// For remarks on [dimensions] see [trackDimensions].
  void trackGoal(
    int goalId, {
    double? revenue,
    Map<String, String>? dimensions,
  }) {
    _initializationCheck();

    validateDimension(dimensions);
    return _track(
      MatomoEvent(
        tracker: this,
        goalId: goalId,
        revenue: revenue,
        dimensions: dimensions,
      ),
    );
  }

  /// Tracks an event.
  ///
  /// To associate this event with a page view, set [pvId]
  /// to the [pvId] of that page, e.g. [TraceableClientMixin.pvId].
  ///
  /// For remarks on [dimensions] see [trackDimensions].
  void trackEvent({
    required EventInfo eventInfo,
    String? pvId,
    Map<String, String>? dimensions,
  }) {
    validateDimension(dimensions);
    return _track(
      MatomoEvent(
        tracker: this,
        eventInfo: eventInfo,
        screenId: pvId,
        dimensions: dimensions,
      ),
    );
  }

  /// Tracks custom visit dimensions.
  ///
  /// The keys of the [dimensions] map correspond with the `dimension[1-999]` parameters.
  /// This means that the keys MUST be named `dimension1`, `dimension2`, `...`.
  ///
  /// The keys of the [dimensions] map will be validated if they follow these rules, and if not, a
  /// [ArgumentError] will be thrown.
  ///
  /// Also note that counting starts at 1 and NOT at 0 as opposed to what is stated
  /// in the [Tracking HTTP API](https://developer.matomo.org/api-reference/tracking-api) documentation.
  void trackDimensions(Map<String, String> dimensions) {
    validateDimension(dimensions);
    return _track(
      MatomoEvent(
        tracker: this,
        dimensions: dimensions,
      ),
    );
  }

  /// Tracks a search.
  ///
  /// [searchKeyword] corresponds with `search`, [searchCategory] with `search_cat` and
  /// [searchCount] with `search_count`.
  ///
  /// For remarks on [dimensions] see [trackDimensions].
  void trackSearch({
    required String searchKeyword,
    String? searchCategory,
    int? searchCount,
    Map<String, String>? dimensions,
  }) {
    validateDimension(dimensions);
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

  /// Tracks a cart update.
  ///
  /// For remarks on [dimensions] see [trackDimensions].
  void trackCartUpdate(
    List<TrackingOrderItem>? trackingOrderItems,
    num? subTotal,
    num? taxAmount,
    num? shippingCost,
    num? discountAmount, {
    Map<String, String>? dimensions,
  }) {
    _initializationCheck();

    validateDimension(dimensions);
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

  /// Tracks an order.
  ///
  /// For remarks on [dimensions] see [trackDimensions].
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

    validateDimension(dimensions);
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

  /// Tracks the click on an outgoing link.
  ///
  /// For remarks on [dimensions] see [trackDimensions].
  void trackOutlink(
    String? link, {
    Map<String, String>? dimensions,
  }) {
    _initializationCheck();

    validateDimension(dimensions);
    return _track(
      MatomoEvent(
        tracker: this,
        link: link,
        dimensions: dimensions,
      ),
    );
  }

  void _track(MatomoEvent event) {
    var ev = event;
    if (_newVisit) {
      ev = ev.copyWith(newVisit: true);
      _newVisit = false;
    }
    queue.add(ev);
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

  Future<void> _saveVisitorId(String? visitorId) async {
    if (visitorId == null) return;

    await _localStorage.setVisitorId(visitorId);
  }

  Future<String?> _getVisitorId() async {
    /// The check is needed here as we don't want to create a new visitor id
    /// with Uuid if the user has opted out.
    if (_cookieless) return null;

    final localId = await _localStorage.getVisitorId();
    return localId ?? const Uuid().v4().replaceAll('-', '').substring(0, 16);
  }

  @visibleForTesting
  void validateDimension(Map<String, String>? dimensions) {
    if (dimensions == null) {
      return;
    }
    for (final dimension in dimensions.keys) {
      if (!dimension.startsWith('dimension')) {
        throw ArgumentError.value(
          dimension,
          'dimension',
          'Invalid custom dimension name!',
        );
      }
      final index = int.tryParse(dimension.substring('dimension'.length));
      if (index == null || index < 1 || index > 999) {
        throw ArgumentError.value(
          dimension,
          'dimension',
          'Invalid custom dimension name!',
        );
      }
    }
  }
}
