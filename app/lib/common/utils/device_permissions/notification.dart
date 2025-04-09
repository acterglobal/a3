import 'dart:io';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/notifications/pages/notification_permission_page.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Handles notification permission request for both Android and iOS platforms
Future<bool> handleNotificationPermission(BuildContext context) async {
  if (Platform.isAndroid) {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    if (androidInfo.version.sdkInt >= 33) {
      if (context.mounted) {
        return await _handleNotificationPermission(context);
      }
    }
  }
  if (Platform.isIOS) {
    if (context.mounted) {
      return await _handleNotificationPermission(context);
    }
  }
  if (isDesktop) return true;
  return false;
}

/// Internal function to handle notification permission request
Future<bool> _handleNotificationPermission(BuildContext context) async {
  bool notificationPermissionGranted = await _checkNotificationPermission();

  if (!notificationPermissionGranted) {
    if (context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog.fullscreen(child: const NotificationPermissionWidget());
        },
      );
      // Check permission again after showing the dialog
      return await _checkNotificationPermission();
    }
  }
  return notificationPermissionGranted;
}

/// Checks if notification permission is granted
Future<bool> _checkNotificationPermission() async {
  final status = await Permission.notification.status;
  return status.isGranted;
}
