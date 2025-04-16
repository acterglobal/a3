import 'dart:io';
import 'package:acter/common/themes/app_theme.dart';
import 'package:device_calendar/device_calendar.dart';

/// Handles calendar permission request for both Android and iOS platforms
Future<bool> isShowCalendarPermissionInfoPage() async {
  if (Platform.isAndroid || Platform.isIOS) {
    final deviceCalendar = DeviceCalendarPlugin();
    final hasPermission = await deviceCalendar.hasPermissions();
    return !hasPermission.data!;
  }
  if (isDesktop) {
    return true;
  }
  return false;
}
