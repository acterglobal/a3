import 'dart:io';
import 'package:acter/config/notifications/init.dart';
import 'package:acter/features/notifications/providers/notification_settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:acter/features/notifications/actions/notification_sync_actions.dart';


final isOnSupportedPlatform = Platform.isAndroid || Platform.isIOS;

class _LabNotificationSettingsTile extends ConsumerWidget {
  final String? title;

  const _LabNotificationSettingsTile({this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final canPush =
        (isOnSupportedPlatform && pushServer.isNotEmpty) ||
        (!isOnSupportedPlatform && ntfyServer.isNotEmpty);
    return SettingsTile.switchTile(
      title: Text(title ?? lang.mobilePushNotifications),
      description: canPush ? Text(lang.noPushServerConfigured) : null,
      initialValue:
          !canPush &&
          (ref.watch(isPushNotificationsActiveProvider).valueOrNull ?? true),
      enabled: !canPush,
      onToggle:
          (newVal) => handleNotificationSyncToggle(
            context: context,
            ref: ref,
            newValue: newVal,
          ),
    );
  }
}

class LabsNotificationsSettingsTile extends AbstractSettingsTile {
  final String? title;

  const LabsNotificationsSettingsTile({this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return _LabNotificationSettingsTile(title: title);
  }
}
