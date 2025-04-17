import 'package:acter/features/calendar_sync/calendar_sync.dart';
import 'package:acter/features/calendar_sync/calendar_sync_permission_page.dart';
import 'package:acter/features/calendar_sync/providers/calendar_sync_active_provider.dart';
import 'package:acter/features/device_permissions/calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Handles the calendar sync toggle action
Future<void> handleCalendarSyncToggle({
  required BuildContext context,
  required WidgetRef ref,
  required bool newValue,
}) async {
  if (newValue) {
    final askPermission = await shouldShowCalendarPermissionInfoPage();
    if (askPermission) {
      if (!context.mounted) return;

      final granted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog.fullscreen(child: const CalendarSyncPermissionWidget());
        },
      );

      if (granted == true) {
        await _enableCalendarSync(ref);
      } else {
        // If permission not granted, keep toggle off
        ref.read(isCalendarSyncActiveProvider.notifier).set(false);
      }
    } else {
      await _enableCalendarSync(ref);
    }
  } else {
    await _disableCalendarSync(ref);
  }
}

/// Enables calendar sync and shows success message
Future<void> _enableCalendarSync(WidgetRef ref) async {
  await initCalendarSync(ignoreRejection: true);
  EasyLoading.showToast('Acter Calendars synced');
  ref.read(isCalendarSyncActiveProvider.notifier).set(true);
}

/// Disables calendar sync and shows success message
Future<void> _disableCalendarSync(WidgetRef ref) async {
  await clearActerCalendars();
  EasyLoading.showToast('Acter Calendars removed');
  ref.read(isCalendarSyncActiveProvider.notifier).set(false);
}
