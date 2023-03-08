import 'package:matomo_tracker/src/platform_info/platform_info_interface.dart';

class PlatformInfoImpl implements PlatformInfoInterface {
  @override
  bool get isWeb => true;

  @override
  bool get isAndroid => false;

  @override
  bool get isIOS => false;

  @override
  bool get isMacOS => false;

  @override
  bool get isWindows => false;

  @override
  bool get isLinux => false;
}
