import 'dart:io' show Platform;

import 'package:matomo_tracker/src/platform_info/platform_info_interface.dart';

class PlatformInfoImpl implements PlatformInfoInterface {
  @override
  bool get isWeb => false;

  @override
  bool get isAndroid => Platform.isAndroid;

  @override
  bool get isIOS => Platform.isIOS;

  @override
  bool get isMacOS => Platform.isMacOS;

  @override
  bool get isWindows => Platform.isWindows;

  @override
  bool get isLinux => Platform.isLinux;
}
