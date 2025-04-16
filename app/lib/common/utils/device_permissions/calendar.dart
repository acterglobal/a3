import 'dart:io';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/calendar_sync/calendar_sync_permission_page.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Handles calendar permission request for both Android and iOS platforms
Future<bool> handleCalendarPermission(BuildContext context) async {
  if (Platform.isAndroid || Platform.isIOS) {
    if (context.mounted) {
      return await _handleCalendarPermission(context);
    }
  }
  if (isDesktop) {
    return true;
  }
  return false;
}

/// Internal function to handle calendar permission request
Future<bool> _handleCalendarPermission(BuildContext context) async {
  bool calendarPermissionGranted = await _checkCalendarPermission();

  if (!calendarPermissionGranted) {
    if (context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog.fullscreen(child: const CalendarSyncPermissionWidget());
        },
      );
      // Check permission again after showing the dialog
      return await _checkCalendarPermission();
    }
  }
  return calendarPermissionGranted;
}

/// Checks if calendar permission is granted
Future<bool> _checkCalendarPermission() async {
  final status = await Permission.calendarFullAccess.request();
  return status.isGranted;
}
