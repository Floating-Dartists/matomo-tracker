/// A fully cross-platform wrap of the Matomo [Tracking HTTP API](https://developer.matomo.org/api-reference/tracking-api)
/// for Flutter.
library matomo_tracker;

export 'src/campaign.dart';
export 'src/content.dart';
export 'src/dispatch_settings.dart';
export 'src/event_info.dart';
export 'src/exceptions.dart';
export 'src/local_storage/local_storage.dart';
export 'src/logger/log_record.dart' show Level;
export 'src/matomo.dart';
export 'src/observers/matomo_global_observer.dart';
export 'src/observers/matomo_local_observer.dart';
export 'src/performance_info.dart';
export 'src/traceable_widget.dart';
export 'src/traceable_widget_mixin.dart';
export 'src/tracking_order_item.dart';
export 'src/visitor.dart';
