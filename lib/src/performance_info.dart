import 'package:matomo_tracker/src/assert.dart';

/// Describes the performance of an action.
///
/// Note that this class is complete in a sense that is is possible
/// to track all types of performance data Matomo supports, even if
/// in an app context, not all performance data might make sense
/// (e.g. [domProcessingTime], [onloadTime]).
///
/// Read more about [Performance Tracking](https://matomo.org/faq/how-to/how-do-i-see-page-performance-reports/).
class PerformanceInfo {
  /// Describes the performance of an action.
  ///
  /// Note: Negative durations are invalid and will result in
  /// [ArgumentError]s.
  factory PerformanceInfo({
    Duration? networkTime,
    Duration? serverTime,
    Duration? transferTime,
    Duration? domProcessingTime,
    Duration? domCompletionTime,
    Duration? onloadTime,
  }) {
    assertDurationNotNegative(value: networkTime, name: 'networkTime');
    assertDurationNotNegative(value: serverTime, name: 'serverTime');
    assertDurationNotNegative(value: transferTime, name: 'transferTime');
    assertDurationNotNegative(
      value: domProcessingTime,
      name: 'domProcessingTime',
    );
    assertDurationNotNegative(
      value: domCompletionTime,
      name: 'domCompletionTime',
    );
    assertDurationNotNegative(value: onloadTime, name: 'onloadTime');

    return PerformanceInfo._(
      networkTime: networkTime,
      serverTime: serverTime,
      transferTime: transferTime,
      domProcessingTime: domProcessingTime,
      domCompletionTime: domCompletionTime,
      onloadTime: onloadTime,
    );
  }

  const PerformanceInfo._({
    this.networkTime,
    this.serverTime,
    this.transferTime,
    this.domProcessingTime,
    this.domCompletionTime,
    this.onloadTime,
  });

  /// How long it took to connect to server.
  ///
  /// Corresponds with `pf_net`.
  final Duration? networkTime;

  /// How long it took the server to generate page.
  ///
  /// Corresponds with `pf_srv`.
  final Duration? serverTime;

  /// How long it takes the browser to download the response from the server.
  ///
  /// Corresponds with `pf_tfr`.
  final Duration? transferTime;

  /// How long the browser spends loading the webpage after the response was
  /// fully received until the user can start interacting with it.
  ///
  /// Corresponds with `pf_dm1`.
  final Duration? domProcessingTime;

  /// How long it takes for the browser to load media and execute any Javascript
  /// code listening for the DOMContentLoaded event.
  ///
  /// Corresponds with `pf_dm2`.
  final Duration? domCompletionTime;

  /// How long it takes the browser to execute Javascript code waiting
  /// for the window.load event.
  ///
  /// Corresponds with `pf_onl`.
  final Duration? onloadTime;

  /// Converts this object to a map.
  ///
  /// Zero durations are omitted in the map.
  Map<String, String> toMap() {
    final pfNet = networkTime?.inMilliseconds ?? 0;
    final pfSrv = serverTime?.inMilliseconds ?? 0;
    final pfTfr = transferTime?.inMilliseconds ?? 0;
    final pfdm1 = domProcessingTime?.inMilliseconds ?? 0;
    final pfdm2 = domCompletionTime?.inMilliseconds ?? 0;
    final pfOnl = onloadTime?.inMilliseconds ?? 0;

    return {
      if (pfNet > 0) 'pf_net': pfNet.toString(),
      if (pfSrv > 0) 'pf_srv': pfSrv.toString(),
      if (pfTfr > 0) 'pf_tfr': pfTfr.toString(),
      if (pfdm1 > 0) 'pf_dm1': pfdm1.toString(),
      if (pfdm2 > 0) 'pf_dm2': pfdm2.toString(),
      if (pfOnl > 0) 'pf_onl': pfOnl.toString(),
    };
  }
}
