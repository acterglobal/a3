import 'package:acter/common/notifications/notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

Future<bool> isRealPhone() async {
  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.isPhysicalDevice;
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    return iosInfo.isPhysicalDevice;
  }
  return false;
}
