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
import 'package:logging/logging.dart';
import 'package:settings_ui/settings_ui.dart';

final _log = Logger('a3::settings::labs_notifications_settings_tile');

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
      onToggle: (newVal) => onToggle(context, ref, newVal),
    );
  }

  Future<void> onToggle(
    BuildContext context,
    WidgetRef ref,
    bool newVal,
  ) async {
    updateFeatureState(ref, LabsFeature.mobilePushNotifications, newVal);
    if (!newVal) return;
    final client = ref.read(alwaysClientProvider);
    EasyLoading.show(status: L10n.of(context).changingSettings);
    try {
      var granted = await setupPushNotifications(client, forced: true);
      if (granted) {
        EasyLoading.dismiss();
        return;
      }
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
      granted = await setupPushNotifications(client, forced: true);
      if (granted) {
        EasyLoading.dismiss();
        return;
      }
      // second attempt, even sending the user to the settings, they do not
      // approve. Let's kick it back off
      updateFeatureState(ref, LabsFeature.mobilePushNotifications, false);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(
        L10n.of(context).changedPushNotificationSettingsSuccessfully,
      );
    } catch (e, st) {
      _log.severe('Failed to change settings', e, st);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).failedToChangePushNotificationSettings(e),
        duration: const Duration(seconds: 3),
      );
    }
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
