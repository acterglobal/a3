import 'package:acter/common/notifications/notifications.dart';
import 'package:acter/common/notifications/util.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_ui/settings_ui.dart';

class _LabNotificationSettingsTile extends ConsumerWidget {
  final String? title;

  const _LabNotificationSettingsTile({this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsTile.switchTile(
      title: Text(title ?? L10n.of(context).mobilePushNotifications),
      description: !isOnSupportedPlatform
          ? Text(L10n.of(context).onlySupportedIosAndAndroid)
          : (pushServer.isEmpty
              ? Text(L10n.of(context).noPushServerConfigured)
              : null),
      initialValue: isOnSupportedPlatform &&
          ref.watch(
            isActiveProvider(LabsFeature.mobilePushNotifications),
          ),
      enabled: isOnSupportedPlatform && pushServer.isNotEmpty,
      onToggle: (newVal) async {
        updateFeatureState(
          ref,
          LabsFeature.mobilePushNotifications,
          newVal,
        );
        if (newVal) {
          final client = ref.read(clientProvider);
          if (client == null) {
            EasyLoading.showError(L10n.of(context).noActiveClient);
            return;
          }
          final granted = await setupPushNotifications(client, forced: true);
          if (!granted) {
            await AppSettings.openAppSettings(
              type: AppSettingsType.notification,
            );
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
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return _LabNotificationSettingsTile(title: title);
  }
}
