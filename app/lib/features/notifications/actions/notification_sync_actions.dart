import 'package:acter/config/notifications/init.dart';
import 'package:acter/features/device_permissions/notification.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/notifications/pages/notification_permission_page.dart';
import 'package:acter/features/notifications/providers/notification_settings_providers.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::notifications::actions');

/// Handles the notification sync toggle action
Future<void> handleNotificationSyncToggle({
  required BuildContext context,
  required WidgetRef ref,
  required bool newValue,
}) async {
  if (newValue) {
    // Turning ON notifications
    final askPermission = await shouldShowNotificationPermissionInfoPage();
    if (askPermission) {
      if (!context.mounted) return;

      final granted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog.fullscreen(child: const NotificationPermissionWidget());
        },
      );

      if (granted != true) {
        ref.read(isPushNotificationsActiveProvider.notifier).set(false);
        return;
      }
    }
    if (context.mounted) {
      await _setupPushNotifications(context, ref);
    }
  } else {
    // Turning OFF notifications
    ref.read(isPushNotificationsActiveProvider.notifier).set(false);
  }
}

/// Sets up push notifications and shows success message
Future<void> _setupPushNotifications(
  BuildContext context,
  WidgetRef ref,
) async {
  final lang = L10n.of(context);
  final client = await ref.read(alwaysClientProvider.future);

  EasyLoading.show(status: lang.changingSettings);
  try {
    var granted = await setupPushNotifications(client, forced: true);
    if (granted) {
      EasyLoading.dismiss();
      ref.read(isPushNotificationsActiveProvider.notifier).set(true);
      return;
    }

    await AppSettings.openAppSettings(type: AppSettingsType.notification);
    granted = await setupPushNotifications(client, forced: true);
    if (granted) {
      EasyLoading.dismiss();
      ref.read(isPushNotificationsActiveProvider.notifier).set(true);
      return;
    }
    // second attempt, even sending the user to the settings, they do not
    // approve. Let's kick it back off
    ref.read(isPushNotificationsActiveProvider.notifier).set(false);
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.showToast(lang.changedPushNotificationSettingsSuccessfully);
  } catch (e, s) {
    _log.severe('Failed to change settings of push notification', e, s);
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.showError(
      lang.failedToChangePushNotificationSettings(e),
      duration: const Duration(seconds: 3),
    );
  }
}
