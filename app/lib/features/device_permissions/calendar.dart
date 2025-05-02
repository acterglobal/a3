import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// Handles calendar permission request for both Android and iOS platforms
Future<bool> shouldShowCalendarPermissionInfoPage() async {
  if (Platform.isAndroid || Platform.isIOS) {
    final status = await Permission.calendarFullAccess.status;
    return !status.isGranted;
  }
  return false;
}
