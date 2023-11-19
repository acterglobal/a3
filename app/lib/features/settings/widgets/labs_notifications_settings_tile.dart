import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_ui/settings_ui.dart';

import 'package:acter/common/notifications/notifications.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';

import 'package:app_settings/app_settings.dart';

class _LabNotificationSettingsTile extends ConsumerWidget {
  final String? title;
  const _LabNotificationSettingsTile({
    this.title,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsTile.switchTile(
      title: Text(title ?? 'Mobile Push Notifications'),
      description: !supportedPlatforms
          ? const Text(
              'Only supported on mobile (iOS & Android) right now',
            )
          : (pushServer.isEmpty
              ? const Text('No push server configured on build')
              : null),
      initialValue: supportedPlatforms &&
          ref.watch(
            isActiveProvider(LabsFeature.mobilePushNotifications),
          ),
      enabled: supportedPlatforms && pushServer.isNotEmpty,
      onToggle: (newVal) async {
        updateFeatureState(
          ref,
          LabsFeature.mobilePushNotifications,
          newVal,
        );
        if (newVal) {
          final client = ref.read(clientProvider);
          if (client == null) {
            EasyLoading.showError('No active client');
            return;
          }
          final granted = await setupPushNotifications(client, forced: true);
          if (!granted) {
            await AppSettings.openAppSettings(
                type: AppSettingsType.notification,);
            final granted = await setupPushNotifications(client, forced: true);
            if (!granted) {
              // second attempt, even sending the user to the settings, they do not
              // approve. Let's kick it back off
              updateFeatureState(
                ref,
                LabsFeature.mobilePushNotifications,
                false,
              );
            }
            return;
          }
        }
      },
    );
  }
}

class LabsNotificationsSettingsTile extends AbstractSettingsTile {
  final String? title;
  const LabsNotificationsSettingsTile({
    this.title,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _LabNotificationSettingsTile(title: title);
  }
}
