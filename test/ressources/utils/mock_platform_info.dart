import 'package:mocktail/mocktail.dart';

import '../mock/mock.dart';

/// Used to mock [PlatformInfo].
/// Usefull to test [MatomoTracker] user agent logic.
///
/// **At least one platform must be set to true**
void setUpPlatformInfo({
  bool isWeb = false,
  bool isAndroid = false,
  bool isIOS = false,
  bool isMacOS = false,
  bool isWindows = false,
  bool isLinux = false,
}) {
  assert(
    isWeb || isAndroid || isIOS || isMacOS || isWindows || isLinux,
    'At least one platform must be set to true',
  );
  when(() => mockPlatformInfo.isWeb).thenReturn(isWeb);
  when(() => mockPlatformInfo.isAndroid).thenReturn(isAndroid);
  when(() => mockPlatformInfo.isIOS).thenReturn(isIOS);
  when(() => mockPlatformInfo.isMacOS).thenReturn(isMacOS);
  when(() => mockPlatformInfo.isWindows).thenReturn(isWindows);
  when(() => mockPlatformInfo.isLinux).thenReturn(isLinux);
}
