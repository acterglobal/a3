import 'package:acter/common/providers/common_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
    return ref.watch(appContentNotificationSetting(appKey)).when(
          data: (v) => innerBuild(context, ref, v),
          error: (error, st) => SettingsTile(
            title: Text('${L10n.of(context).error}: $error'),
          ),
          loading: () => Skeletonizer(
            child: SettingsTile.switchTile(
              initialValue: true,
              onToggle: null,
              title: Text(title),
            ),
          ),
        );
  }

  Widget innerBuild(
    BuildContext context,
    WidgetRef ref,
    bool currentValue,
  ) {
    return SettingsTile.switchTile(
      title: Text(title),
      description: description != null ? Text(description!) : null,
      initialValue: currentValue,
      enabled: enabled ?? true,
      onToggle: (newVal) async {
        final settingsSetter =
            await ref.read(notificationSettingsProvider.future);
        await settingsSetter.setGlobalContentSetting(appKey, newVal);
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
    required this.title,
    required this.appKey,
    this.description,
    this.enabled,
    super.key,
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
