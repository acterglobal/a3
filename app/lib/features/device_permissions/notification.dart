import 'dart:io';
import 'package:acter/common/themes/app_theme.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Handles notification permission request for both Android and iOS platforms
Future<bool> shouldShowNotificationPermissionInfoPage() async {
  if (Platform.isAndroid) {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    if (androidInfo.version.sdkInt >= 33) {
      final status = await Permission.notification.status;
      return !status.isGranted;
    }
  }
  if (Platform.isIOS) {
    final status = await Permission.notification.status;
    return !status.isGranted;
  }
  if (isDesktop) {
    return true;
  }
  return false;
}
