import 'dart:async';
import 'dart:collection';

import 'package:clock/clock.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:matomo_tracker/src/assert.dart';
import 'package:matomo_tracker/src/campaign.dart';
import 'package:matomo_tracker/src/content.dart';
import 'package:matomo_tracker/src/dispatch_settings.dart';
import 'package:matomo_tracker/src/event_info.dart';
import 'package:matomo_tracker/src/exceptions.dart';
import 'package:matomo_tracker/src/local_storage/cookieless_storage.dart';
import 'package:matomo_tracker/src/local_storage/local_storage.dart';
import 'package:matomo_tracker/src/local_storage/shared_prefs_storage.dart';
import 'package:matomo_tracker/src/logger/log_record.dart';
import 'package:matomo_tracker/src/logger/logger.dart';
import 'package:matomo_tracker/src/matomo_action.dart';
import 'package:matomo_tracker/src/matomo_dispatcher.dart';
import 'package:matomo_tracker/src/performance_info.dart';
import 'package:matomo_tracker/src/persistent_queue.dart';
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

  @visibleForTesting
  MatomoDispatcher get dispatcher => _dispatcher;

  late MatomoDispatcher _dispatcher;

  static final instance = MatomoTracker._internal();

  /// The ID of the website we're tracking a visit/action for.
  ///
  /// Corresponds with `idsite`.
  late final String siteId;

  /// The url of the Matomo endpoint.
  ///
  /// E.g.: `https://example.com/matomo.php`
  ///
  /// Should not be confused with the `url` tracking parameter
  /// which is constructed by combining [contentBase] with a `path`
  /// (e.g. in [trackPageViewWithName]).
  ///
  /// You can use [setUrl] to change this value after initialization.
  String get url {
    if (_url case final url?) {
      return url;
    }
    throw const UninitializedMatomoInstanceException();
  }

  String? _url;

  /// Sets the url of the Matomo endpoint and updates the dispatcher.
  ///
  /// Note that this will change the url used by the request that are still
  /// in the queue.
  void setUrl(String newUrl) {
    _initializationCheck();

    _url = newUrl;
    _dispatcher = _dispatcher.copyWith(baseUrl: newUrl);
  }

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

  /// Whether to attach `pvId` and `path` to `track...` calls automatically.
  ///
  /// There most actions can be associated with page views by setting a `pvId`
  /// (what is the abbreviation of page view id). If [attachLastScreenInfo] is
  /// `true` and there is a last page view tracked by [trackPageViewWithName] (or
  /// a method/class that uses it like [trackPageView], [TraceableClientMixin],
  /// [TraceableWidget]) the last recorded `pvId` is automatically used unless
  /// it is overwritten in that action.
  ///
  /// Similarly, most actions can have a `path` which usually represents the page
  /// the action happend on. If [attachLastScreenInfo] is `true` and there  is a
  /// last page view tracked by a method mentioned above, the last recorded `path`
  /// is automatically used unless it is overwritten in that action.
  late final bool attachLastScreenInfo;

  /// The user agent is used to detect the operating system and browser used.
  late final String? userAgent;

  /// Custom http headers to add to each request.
  late final Map<String, String> customHeaders;

  /// URL for the current action.
  ///
  /// For the tracking of screens (e.g. with [trackPageViewWithName]) this is combined
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
  late final Queue<Map<String, String>> queue;

  @visibleForTesting
  late Timer dequeueTimer;

  @visibleForTesting
  Timer? pingTimer;

  late sync.Lock _lock;

  String? _tokenAuth;

  String? get authToken => _tokenAuth;

  /// Controls how actions are dispatched.
  late final DispatchSettings _dispatchSettings;

  late final Duration? _pingInterval;

  late bool _newVisit;

  MatomoAction? _lastPageView;

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
  /// is a new visit or not. In practice, this will be used as the `newVisit`
  /// parameter in the first `track...` method call but only if the `newVisit`
  /// parameter in that method call is left to `null`.
  ///
  /// The [visitorId] should have a length of 16 characters otherwise an
  /// [ArgumentError] will be thrown. This parameter corresponds with the
  /// `_id` and should not be confused with the user id `uid`. See the
  /// [Visitor] class for additional remarks. It is recommended to leave this
  /// to `null` to use an automatically generated id.
  ///
  /// If [cookieless] is set to true, a [CookielessStorage] instance will be
  /// used. This means that the first_visit and the user_id will be stored in
  /// memory and will be lost when the app is closed.
  ///
  /// The [pingInterval] is used to set the interval in which pings are
  /// send to Matomo to circumvent the [last page viewtime issue](https://github.com/Floating-Dartists/matomo-tracker/issues/78).
  /// To deactivate pings, set this to `null`. The default value is a good
  /// compromise between accuracy and network traffic.
  ///
  /// It is recommended to leave [userAgent] to `null` so it will be detected
  /// automatically.
  Future<void> initialize({
    required String siteId,
    required String url,
    bool newVisit = true,
    String? visitorId,
    String? uid,
    String? contentBaseUrl,
    DispatchSettings dispatchSettings = const DispatchSettings.nonPersistent(),
    Duration? pingInterval = const Duration(seconds: 30),
    String? tokenAuth,
    LocalStorage? localStorage,
    PackageInfo? packageInfo,
    PlatformInfo? platformInfo,
    bool cookieless = false,
    Level verbosityLevel = Level.off,
    Map<String, String> customHeaders = const {},
    String? userAgent,
    bool attachLastScreenInfo = true,
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

    assertDurationNotNegative(
      value: dispatchSettings.dequeueInterval,
      name: 'dequeueInterval',
    );
    assertDurationNotNegative(
      value: pingInterval,
      name: 'pingInterval',
    );

    log.setLogging(level: verbosityLevel);

    this.siteId = siteId;
    _url = url;
    this.customHeaders = customHeaders;
    _pingInterval = pingInterval;
    _lock = sync.Lock();
    _platformInfo = platformInfo ?? PlatformInfo.instance;
    _cookieless = cookieless;
    _tokenAuth = tokenAuth;
    _newVisit = newVisit;
    this.attachLastScreenInfo = attachLastScreenInfo;
    _dispatchSettings = dispatchSettings;

    final effectiveLocalStorage = localStorage ?? SharedPrefsStorage();
    _localStorage = cookieless
        ? CookielessStorage(storage: effectiveLocalStorage)
        : effectiveLocalStorage;

    final onLoad = _dispatchSettings.onLoad;
    queue = _dispatchSettings.persistentQueue && onLoad != null
        ? await PersistentQueue.load(
            storage: _localStorage,
            onLoadFilter: onLoad,
          )
        : Queue();

    final localVisitorId = visitorId ?? await _getVisitorId();
    _visitor = Visitor(id: localVisitorId, uid: uid);

    // User agent
    this.userAgent = userAgent ?? await getUserAgent();

    _dispatcher = MatomoDispatcher(
      baseUrl: url,
      tokenAuth: tokenAuth,
      userAgent: this.userAgent,
      log: log,
    );

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
      'Matomo Initialized: firstVisit=$firstVisit; lastVisit=$now; visitCount=$visitCount; visitorId=$visitorId; contentBase=$contentBase; resolution=${screenResolution.width}x${screenResolution.height}; userAgent=${this.userAgent}',
    );
    _initialized = true;

    dequeueTimer = Timer.periodic(_dispatchSettings.dequeueInterval, (_) {
      _dequeue();
    });

    if (pingInterval != null) {
      pingTimer = Timer.periodic(pingInterval, (_) {
        _ping();
      });
    }

    if (queue.isNotEmpty) {
      await dispatchActions();
    }
  }

  @visibleForTesting
  Future<String?> getUserAgent({
    DeviceInfoPlugin? deviceInfoPlugin,
  }) async {
    final result = await _getUserAgentInner(deviceInfoPlugin);
    return result != null ? Uri.encodeComponent(result) : null;
  }

  Future<String?> _getUserAgentInner(DeviceInfoPlugin? deviceInfoPlugin) async {
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

  /// Cancel the timer which checks the queued actions to send
  ///
  /// This will not clear the queue.
  void dispose() {
    pingTimer?.cancel();
    dequeueTimer.cancel();
    log.clearListeners();
  }

  // Pause tracker
  void pause() {
    pingTimer?.cancel();
    _ping();
    dequeueTimer.cancel();
    _dequeue();
  }

  // Resume tracker
  void resume() {
    final pingInterval = _pingInterval;
    if (pingInterval != null) {
      if (!(pingTimer?.isActive ?? false)) {
        pingTimer = Timer.periodic(pingInterval, (_) {
          _ping();
        });
      }
    }
    if (!dequeueTimer.isActive) {
      dequeueTimer = Timer.periodic(_dispatchSettings.dequeueInterval, (timer) {
        _dequeue();
      });
    }
  }

  /// Iterate on the actions in the queue and send them to Matomo.
  Future<void> dispatchActions() {
    return _dequeue();
  }

  /// Drops all actions queued for dispatching.
  void dropActions() {
    queue.clear();
  }

  /// This will register a page view with [trackPageViewWithName] by using the
  /// `context.widget.toStringShort()` as `actionName` value.
  ///
  /// {@template pvid_screen_track_parameter}
  /// [pvId] is a  6 character unique ID that can later be used to associate
  /// other actions (like [trackEvent]) with this page view. If `null`,
  /// a random id will be generated (recommended). Also see [attachLastScreenInfo].
  /// {@endtemplate}
  ///
  /// {@template campaign_and_path_track_parameter}
  /// [path] is a string that identifies the path of the screen where this action
  /// happend. If not `null`, it will be appended to [contentBase] to create a
  /// URL. This combination corresponds with `url`. Also see [attachLastScreenInfo].
  /// Setting [path] manually will take precedance over [attachLastScreenInfo].
  ///
  /// [campaign] can be a campaign that lead to this action. Setting this multiple
  /// times during an apps lifetime can have some side effects, see the [Campaign]
  /// class for more information.
  /// {@endtemplate}
  ///
  /// {@template dimensions_track_parameter}
  /// For remarks on [dimensions] see [trackDimensions].
  /// {@endtemplate}
  ///
  /// {@template new_visit_track_parameter}
  /// The [newVisit] parameter can be used to make this action the begin
  /// of a new visit. If it's left to `null` and this is the first `track...`
  /// call after [MatomoTracker.initialize], the `newVisit` from there will
  /// be used.
  /// {@endtemplate}
  void trackPageView({
    required BuildContext context,
    String? pvId,
    String? path,
    Campaign? campaign,
    Map<String, String>? dimensions,
    PerformanceInfo? performanceInfo,
    bool? newVisit,
  }) {
    final actionName = context.widget.toStringShort();

    trackPageViewWithName(
      actionName: actionName,
      pvId: pvId,
      path: path,
      campaign: campaign,
      dimensions: dimensions,
      performanceInfo: performanceInfo,
      newVisit: _inferNewVisit(newVisit),
    );
  }

  /// Registers a page view.
  ///
  /// [actionName] represents the page name, here used to identify the
  /// screen with a proper name. Corresponds with `action_name`.
  ///
  /// {@macro pvid_screen_track_parameter}
  ///
  /// {@macro campaign_and_path_track_parameter}
  ///
  /// {@macro dimensions_track_parameter}
  ///
  /// {@macro new_visit_track_parameter}
  void trackPageViewWithName({
    required String actionName,
    String? pvId,
    String? path,
    Campaign? campaign,
    Map<String, String>? dimensions,
    PerformanceInfo? performanceInfo,
    bool? newVisit,
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
    final lastPageView = MatomoAction(
      action: actionName,
      path: path,
      campaign: campaign,
      dimensions: dimensions,
      pvId: pvId ?? randomAlphaNumeric(6),
      performanceInfo: performanceInfo,
      newVisit: _inferNewVisit(newVisit),
    );
    _lastPageView = lastPageView;
    return _track(lastPageView);
  }

  /// Tracks a conversion for a goal.
  ///
  /// The [id] corresponds with `idgoal` and [revenue] with `revenue`.
  ///
  /// {@template pvid_other_track_parameter}
  /// To associate this action with a page view, enable [attachLastScreenInfo] and
  /// leave [pvId] to `null` here or set [pvId] to the [pvId] of that page view
  /// manually, e.g. [TraceableClientMixin.pvId]. Setting [pvId] manually will
  /// take precedance over [attachLastScreenInfo].
  /// {@endtemplate}
  ///
  /// {@macro campaign_and_path_track_parameter}
  ///
  /// {@macro dimensions_track_parameter}
  ///
  /// {@macro new_visit_track_parameter}
  void trackGoal({
    required int id,
    double? revenue,
    String? pvId,
    String? path,
    Campaign? campaign,
    Map<String, String>? dimensions,
    bool? newVisit,
  }) {
    _initializationCheck();

    validateDimension(dimensions);
    return _track(
      MatomoAction(
        goalId: id,
        revenue: revenue,
        pvId: _inferPvId(pvId),
        path: _inferPath(path),
        campaign: campaign,
        dimensions: dimensions,
        newVisit: _inferNewVisit(newVisit),
      ),
    );
  }

  /// Tracks an event.
  ///
  /// {@macro pvid_other_track_parameter}
  ///
  /// {@macro campaign_and_path_track_parameter}
  ///
  /// {@macro dimensions_track_parameter}
  ///
  /// {@macro new_visit_track_parameter}
  void trackEvent({
    required EventInfo eventInfo,
    String? pvId,
    String? path,
    Campaign? campaign,
    Map<String, String>? dimensions,
    bool? newVisit,
  }) {
    validateDimension(dimensions);
    return _track(
      MatomoAction(
        eventInfo: eventInfo,
        pvId: _inferPvId(pvId),
        path: _inferPath(path),
        campaign: campaign,
        dimensions: dimensions,
        newVisit: _inferNewVisit(newVisit),
      ),
    );
  }

  /// Tracks custom dimensions.
  ///
  /// It is recommended to set the `dimensions` parameter in one of the other
  /// track calls instead of using this method (since it will log an additional
  /// page view).
  ///
  /// The keys of the [dimensions] map correspond with the `dimension[1-999]`
  /// parameters. This means that the keys MUST be named `dimension1`,
  /// `dimension2`, `...`.
  ///
  /// The keys of the [dimensions] map will be validated if they follow these
  /// rules, and if not, a [ArgumentError] will be thrown.
  ///
  /// To see the dimensions in the Matomo dashboard, make sure to add them in the
  /// dashboard first.
  ///
  /// {@macro pvid_other_track_parameter}
  ///
  /// {@macro campaign_and_path_track_parameter}
  ///
  /// {@macro new_visit_track_parameter}
  void trackDimensions({
    required Map<String, String> dimensions,
    String? pvId,
    String? path,
    Campaign? campaign,
    bool? newVisit,
  }) {
    validateDimension(dimensions);
    return _track(
      MatomoAction(
        pvId: _inferPvId(pvId),
        path: _inferPath(path),
        campaign: campaign,
        dimensions: dimensions,
        newVisit: _inferNewVisit(newVisit),
      ),
    );
  }

  /// Tracks a search.
  ///
  /// [searchKeyword] corresponds with `search`, [searchCategory] with
  /// `search_cat` and [searchCount] with `search_count`.
  ///
  /// {@macro pvid_other_track_parameter}
  ///
  /// {@macro campaign_and_path_track_parameter}
  ///
  /// {@macro dimensions_track_parameter}
  ///
  /// {@macro new_visit_track_parameter}
  void trackSearch({
    required String searchKeyword,
    String? searchCategory,
    int? searchCount,
    String? pvId,
    String? path,
    Campaign? campaign,
    Map<String, String>? dimensions,
    bool? newVisit,
  }) {
    validateDimension(dimensions);
    return _track(
      MatomoAction(
        searchKeyword: searchKeyword,
        searchCategory: searchCategory,
        searchCount: searchCount,
        pvId: _inferPvId(pvId),
        path: _inferPath(path),
        campaign: campaign,
        dimensions: dimensions,
        newVisit: _inferNewVisit(newVisit),
      ),
    );
  }

  /// Tracks a cart update.
  ///
  /// {@macro pvid_other_track_parameter}
  ///
  /// {@macro campaign_and_path_track_parameter}
  ///
  /// {@macro dimensions_track_parameter}
  ///
  /// {@macro new_visit_track_parameter}
  void trackCartUpdate({
    List<TrackingOrderItem>? trackingOrderItems,
    num? subTotal,
    num? taxAmount,
    num? shippingCost,
    num? discountAmount,
    String? pvId,
    String? path,
    Campaign? campaign,
    Map<String, String>? dimensions,
    bool? newVisit,
  }) {
    _initializationCheck();

    validateDimension(dimensions);
    return _track(
      MatomoAction(
        // goalId should be set to 0 to track an ecommerce interaction
        goalId: 0,
        trackingOrderItems: trackingOrderItems,
        subTotal: subTotal,
        taxAmount: taxAmount,
        shippingCost: shippingCost,
        discountAmount: discountAmount,
        pvId: _inferPvId(pvId),
        path: _inferPath(path),
        campaign: campaign,
        dimensions: dimensions,
        newVisit: _inferNewVisit(newVisit),
      ),
    );
  }

  /// Tracks an ecommerce order.
  ///
  /// [id] corresponds with `ec_id`, [trackingOrderItems] with `ec_items`,
  /// [revenue] with `revenue`, [subTotal] with `ec_st`, [taxAmount] with
  /// `ec_tx`, [shippingCost] with `ec_sh`, [discountAmount] with `ec_dt`.
  ///
  /// {@macro pvid_other_track_parameter}
  ///
  /// {@macro campaign_and_path_track_parameter}
  ///
  /// {@macro dimensions_track_parameter}
  ///
  /// {@macro new_visit_track_parameter}
  void trackOrder({
    required String id,
    required double revenue,
    List<TrackingOrderItem>? trackingOrderItems,
    num? subTotal,
    num? taxAmount,
    num? shippingCost,
    num? discountAmount,
    String? pvId,
    String? path,
    Campaign? campaign,
    Map<String, String>? dimensions,
    bool? newVisit,
  }) {
    _initializationCheck();

    validateDimension(dimensions);
    return _track(
      MatomoAction(
        // goalId should be set to 0 to track an ecommerce interaction
        goalId: 0,
        orderId: id,
        trackingOrderItems: trackingOrderItems,
        revenue: revenue,
        subTotal: subTotal,
        taxAmount: taxAmount,
        shippingCost: shippingCost,
        discountAmount: discountAmount,
        pvId: _inferPvId(pvId),
        path: _inferPath(path),
        campaign: campaign,
        dimensions: dimensions,
        newVisit: _inferNewVisit(newVisit),
      ),
    );
  }

  /// Tracks the click on an outgoing link.
  ///
  /// [link] corresponds with `link`.
  ///
  /// {@macro pvid_other_track_parameter}
  ///
  /// {@macro campaign_and_path_track_parameter}
  ///
  /// {@macro dimensions_track_parameter}
  ///
  /// {@macro new_visit_track_parameter}
  void trackOutlink({
    required String link,
    String? pvId,
    String? path,
    Campaign? campaign,
    Map<String, String>? dimensions,
    bool? newVisit,
  }) {
    _initializationCheck();

    validateDimension(dimensions);
    return _track(
      MatomoAction(
        link: link,
        pvId: _inferPvId(pvId),
        path: _inferPath(path),
        campaign: campaign,
        dimensions: dimensions,
        newVisit: _inferNewVisit(newVisit),
      ),
    );
  }

  /// Tracks a content impression.
  ///
  /// Later, if the user interacts with the content (e.g. taps on it),
  /// call [trackContentInteraction].
  ///
  /// {@macro pvid_other_track_parameter}
  ///
  /// {@macro campaign_and_path_track_parameter}
  ///
  /// {@macro dimensions_track_parameter}
  ///
  /// {@macro new_visit_track_parameter}
  void trackContentImpression({
    required Content content,
    String? pvId,
    String? path,
    Campaign? campaign,
    Map<String, String>? dimensions,
    bool? newVisit,
  }) {
    return _track(
      MatomoAction(
        content: content,
        pvId: _inferPvId(pvId),
        path: _inferPath(path),
        campaign: campaign,
        dimensions: dimensions,
        newVisit: _inferNewVisit(newVisit),
      ),
    );
  }

  /// Tracks a content interaction.
  ///
  /// Use [trackContentImpression] instead if the content was shown
  /// to the user, but he did not interact with it.
  ///
  /// The [interaction] corresponds with `c_i` and should
  /// describe the type of interaction, e.g. `tap` or `swipe`.
  ///
  /// {@macro pvid_other_track_parameter}
  ///
  /// {@macro campaign_and_path_track_parameter}
  ///
  /// {@macro dimensions_track_parameter}
  ///
  /// Note that this method is missing a `newVisit` parameter on purpose since
  /// it doesn't make sense to have an interaction without an impression first,
  /// and then the impression would mark the new visit, not the interaction.
  void trackContentInteraction({
    required Content content,
    required String interaction,
    String? pvId,
    String? path,
    Campaign? campaign,
    Map<String, String>? dimensions,
  }) {
    return _track(
      MatomoAction(
        content: content,
        contentInteraction: interaction,
        pvId: _inferPvId(pvId),
        path: _inferPath(path),
        campaign: campaign,
        dimensions: dimensions,
      ),
    );
  }

  void _track(MatomoAction action) => queue.add(action.toMap(this));

  void _ping() {
    final lastPageView = _lastPageView;
    if (lastPageView != null) {
      _track(
        lastPageView.copyWith(
          ping: true,
          newVisit: false,
        ),
      );
    }
  }

  Future<void> _dequeue() async {
    if (!_initialized) {
      throw const UninitializedMatomoInstanceException();
    }

    log.finest('Processing queue ${queue.length}');

    if (!_lock.locked) {
      return _lock.synchronized(() async {
        final actions = List<Map<String, String>>.of(queue);
        if (!_optOut) {
          final hasSucceeded = await _dispatcher.sendBatch(
            actions: actions,
            customHeaders: customHeaders,
          );
          if (hasSucceeded) {
            // As the operation is asynchronous we need to be sure to remove
            // only the actions that were sent in the batch.
            queue.removeWhere(actions.contains);
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

  String? _inferPvId(String? pvId) =>
      pvId ?? (attachLastScreenInfo ? _lastPageView?.pvId : null);

  bool _inferNewVisit(bool? localNewVisit) {
    final globalNewVisit = _newVisit;
    _newVisit = false;
    return localNewVisit ?? globalNewVisit;
  }

  String? _inferPath(String? path) =>
      path ?? (attachLastScreenInfo ? _lastPageView?.path : null);
}
