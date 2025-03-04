import 'package:acter/common/extensions/options.dart';
import 'package:acter/features/notifications/providers/notification_settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::settings::app_notifications');

class _AppNotificationSettingsTile extends ConsumerWidget {
  final String title;
  final String appKey;
  final String? description;
  final bool? enabled;

  const _AppNotificationSettingsTile({
    required this.title,
    required this.appKey,
    this.description,
    this.enabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingLoader = ref.watch(appContentNotificationSetting(appKey));
    return settingLoader.when(
      data: (v) => innerBuild(context, ref, v),
      error: (e, s) {
        _log.severe(
          'Fetching of app content notification setting failed',
          e,
          s,
        );
        return SettingsTile(title: Text(L10n.of(context).loadingFailed(e)));
      },
      loading:
          () => Skeletonizer(
            child: SettingsTile.switchTile(
              initialValue: true,
              onToggle: null,
              title: Text(title),
            ),
          ),
    );
  }

  Widget innerBuild(BuildContext context, WidgetRef ref, bool currentValue) {
    return SettingsTile.switchTile(
      title: Text(title),
      description: description.map((desc) => Text(desc)),
      initialValue: currentValue,
      enabled: enabled ?? true,
      onToggle: (newVal) async {
        final settings = await ref.read(notificationSettingsProvider.future);
        await settings.setGlobalContentSetting(appKey, newVal);
      },
    );
  }
}

class AppsNotificationsSettingsTile extends AbstractSettingsTile {
  final String title;
  final String? description;
  final String appKey;
  final bool? enabled;

  const AppsNotificationsSettingsTile({
    super.key,
    required this.title,
    this.description,
    required this.appKey,
    this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return _AppNotificationSettingsTile(
      title: title,
      enabled: enabled,
      description: description,
      appKey: appKey,
    );
  }
}
