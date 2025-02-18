import 'package:acter/common/extensions/acter_build_context.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/settings/pages/settings_page.dart';
import 'package:acter/features/settings/providers/app_settings_provider.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter/features/settings/widgets/options_settings_tile.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::settings::chat_settings');

class _AutoDownloadTile extends ConsumerWidget {
  const _AutoDownloadTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final settingsLoader = ref.watch(userAppSettingsProvider);
    return settingsLoader.when(
      data: (settings) => OptionsSettingsTile<String>(
        selected: settings.autoDownloadChat() ?? 'always',
        title: lang.chatSettingsAutoDownload,
        explainer: lang.chatSettingsAutoDownloadExplainer,
        options: [
          ('always', lang.chatSettingsAutoDownloadAlways),
          ('wifiOnly', lang.chatSettingsAutoDownloadWifiOnly),
          ('never', lang.chatSettingsAutoDownloadNever),
        ],
        onSelect: (newVal) async {
          EasyLoading.show(status: lang.settingsSubmitting);
          try {
            final updater = settings.updateBuilder();
            updater.autoDownloadChat(newVal);
            await updater.send();
            if (!context.mounted) {
              EasyLoading.dismiss();
              return;
            }
            EasyLoading.showToast(
              lang.settingsSubmittingSuccess,
              toastPosition: EasyLoadingToastPosition.bottom,
            );
          } catch (e, s) {
            _log.severe('Failure submitting settings', e, s);
            if (!context.mounted) {
              EasyLoading.dismiss();
              return;
            }
            EasyLoading.showError(
              lang.settingsSubmittingFailed(e),
              duration: const Duration(seconds: 3),
            );
          }
        },
      ),
      error: (e, s) {
        _log.severe('Failed to load user app settings', e, s);
        return SettingsTile.navigation(
          title: Text(lang.loadingFailed(e)),
        );
      },
      loading: () => SettingsTile.switchTile(
        title: Skeletonizer(
          child: Text(lang.chatSettingsAutoDownload),
        ),
        enabled: false,
        description: Skeletonizer(
          child: Text(lang.sharedCalendarAndEvents),
        ),
        initialValue: false,
        onToggle: (newVal) {},
      ),
    );
  }
}

class _TypingNoticeTile extends ConsumerWidget {
  const _TypingNoticeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final settingsLoader = ref.watch(userAppSettingsProvider);
    return settingsLoader.when(
      data: (settings) => SettingsTile.switchTile(
        title: Text(lang.chatSettingsTyping),
        description: Text(lang.chatSettingsTypingExplainer),
        enabled: true,
        initialValue: settings.typingNotice() ?? true,
        onToggle: (newVal) async {
          EasyLoading.show(status: lang.settingsSubmitting);
          try {
            final updater = settings.updateBuilder();
            updater.typingNotice(newVal);
            await updater.send();
            if (!context.mounted) {
              EasyLoading.dismiss();
              return;
            }
            EasyLoading.showToast(
              lang.settingsSubmittingSuccess,
              toastPosition: EasyLoadingToastPosition.bottom,
            );
          } catch (e, s) {
            _log.severe('Failure submitting settings', e, s);
            if (!context.mounted) {
              EasyLoading.dismiss();
              return;
            }
            EasyLoading.showError(
              lang.settingsSubmittingFailed(e),
              duration: const Duration(seconds: 3),
            );
          }
        },
      ),
      error: (e, s) {
        _log.severe('Failed to load user app settings', e, s);
        return SettingsTile.navigation(
          title: Text(lang.loadingFailed(e)),
        );
      },
      loading: () => SettingsTile.switchTile(
        title: Skeletonizer(
          child: Text(lang.chatSettingsTyping),
        ),
        enabled: false,
        description: Skeletonizer(
          child: Text(lang.chatSettingsTypingExplainer),
        ),
        initialValue: false,
        onToggle: (newVal) {},
      ),
    );
  }
}

class _SystemLinksTile extends ConsumerWidget {
  const _SystemLinksTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openSysSettings = ref.watch(openSystemLinkSettingsProvider);
    final lang = L10n.of(context);
    return OptionsSettingsTile<OpenSystemLinkSetting>(
      selected: openSysSettings,
      title: lang.systemLinksTitle,
      explainer: lang.systemLinksExplainer,
      options: [
        (OpenSystemLinkSetting.open, lang.systemLinksOpen),
        (OpenSystemLinkSetting.copy, lang.systemLinksCopy),
      ],
      onSelect: (newVal) async {
        await ref.read(openSystemLinkSettingsProvider.notifier).set(newVal);
      },
    );
  }
}

class BehaviorSettingsPage extends ConsumerWidget {
  const BehaviorSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return WithSidebar(
      sidebar: const SettingsPage(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(lang.behaviorSettingsTitle),
          automaticallyImplyLeading: !context.isLargeScreen,
        ),
        body: SettingsList(
          sections: [
            SettingsSection(
              title: Text(lang.general),
              tiles: [
                SettingsTile.navigation(
                  leading: Icon(Atlas.language_translation),
                  title: Text(lang.language),
                  description: Text(lang.changeAppLanguage),
                  onPressed: (context) {
                    if (context.isLargeScreen) {
                      context.pushReplacementNamed(Routes.settingLanguage.name);
                    } else {
                      context.pushNamed(Routes.settingLanguage.name);
                    }
                  },
                ),
              ],
            ),
            SettingsSection(
              title: Text(lang.chat),
              tiles: [
                CustomSettingsTile(child: _AutoDownloadTile()),
                CustomSettingsTile(child: _TypingNoticeTile()),
                SettingsTile.switchTile(
                  title: Text(lang.chatSettingsReadReceipts),
                  description: Text(lang.chatSettingsReadReceiptsExplainer),
                  enabled: false,
                  initialValue: false,
                  onToggle: (newVal) {},
                ),
              ],
            ),
            SettingsSection(
              title: Text(lang.customizationsTitle),
              tiles: [CustomSettingsTile(child: _SystemLinksTile())],
            ),
          ],
        ),
      ),
    );
  }
}
