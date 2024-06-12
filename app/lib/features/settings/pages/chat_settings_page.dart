import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/settings/pages/settings_page.dart';
import 'package:acter/features/settings/providers/app_settings_provider.dart';
import 'package:acter/features/settings/widgets/options_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::settings::chat_settings');

class ChatSettingsPage extends ConsumerWidget {
  const ChatSettingsPage({super.key});

  AbstractSettingsTile _autoDownload(BuildContext context, WidgetRef ref) {
    return ref.watch(userAppSettingsProvider).when(
          data: (settings) => OptionsSettingsTile<String>(
            selected: settings.autoDownloadChat() ?? 'always',
            title: L10n.of(context).chatSettingsAutoDownload,
            explainer: L10n.of(context).chatSettingsAutoDownloadExplainer,
            options: [
              ('always', L10n.of(context).chatSettingsAutoDownloadAlways),
              ('wifiOnly', L10n.of(context).chatSettingsAutoDownloadWifiOnly),
              ('never', L10n.of(context).chatSettingsAutoDownloadNever),
            ],
            onSelect: (String newVal) async {
              EasyLoading.show(status: L10n.of(context).settingsSubmitting);
              try {
                final updater = settings.updateBuilder();
                updater.autoDownloadChat(newVal);
                await updater.send();
                EasyLoading.showToast(
                  // ignore: use_build_context_synchronously
                  L10n.of(context).settingsSubmittingSuccess,
                  toastPosition: EasyLoadingToastPosition.bottom,
                );
              } catch (error, stackTrace) {
                _log.severe('Failure submitting settings', error, stackTrace);
                EasyLoading.showError(
                  // ignore: use_build_context_synchronously
                  L10n.of(context).settingsSubmittingFailed(error),
                );
              }
            },
          ),
          error: (error, stack) => SettingsTile.navigation(
            title: Text(
              L10n.of(context).failed,
            ),
          ),
          loading: () => SettingsTile.switchTile(
            title: Skeletonizer(
              child: Text(L10n.of(context).chatSettingsAutoDownload),
            ),
            enabled: false,
            description: Skeletonizer(
              child: Text(L10n.of(context).sharedCalendarAndEvents),
            ),
            initialValue: false,
            onToggle: (newVal) {},
          ),
        );
  }

  AbstractSettingsTile _typingNotice(
    BuildContext context,
    WidgetRef ref,
  ) {
    return ref.watch(userAppSettingsProvider).when(
          data: (settings) => SettingsTile.switchTile(
            title: Text(L10n.of(context).chatSettingsTyping),
            description: Text(
              L10n.of(context).chatSettingsTypingExplainer,
            ),
            enabled: true,
            initialValue: settings.typingNotice() ?? true,
            onToggle: (newVal) async {
              EasyLoading.show(status: L10n.of(context).settingsSubmitting);
              try {
                final updater = settings.updateBuilder();
                updater.typingNotice(newVal);
                await updater.send();
                EasyLoading.showToast(
                  // ignore: use_build_context_synchronously
                  L10n.of(context).settingsSubmittingSuccess,
                  toastPosition: EasyLoadingToastPosition.bottom,
                );
              } catch (error, stackTrace) {
                _log.severe('Failure submitting settings', error, stackTrace);
                EasyLoading.showError(
                  // ignore: use_build_context_synchronously
                  L10n.of(context).settingsSubmittingFailed(error),
                );
              }
            },
          ),
          error: (error, stack) => SettingsTile.navigation(
            title: Text(
              L10n.of(context).failed,
            ),
          ),
          loading: () => SettingsTile.switchTile(
            title: Skeletonizer(
              child: Text(L10n.of(context).chatSettingsTyping),
            ),
            enabled: false,
            description: Skeletonizer(
              child: Text(L10n.of(context).chatSettingsTypingExplainer),
            ),
            initialValue: false,
            onToggle: (newVal) {},
          ),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WithSidebar(
      sidebar: const SettingsPage(),
      child: Scaffold(
        appBar: AppBar(title: Text(L10n.of(context).chat)),
        body: SettingsList(
          sections: [
            SettingsSection(
              title: Text(L10n.of(context).defaultModes),
              tiles: [
                _autoDownload(context, ref),
                _typingNotice(context, ref),
                SettingsTile.switchTile(
                  title: Text(L10n.of(context).chatSettingsReadReceipts),
                  description: Text(
                    L10n.of(context).chatSettingsReadReceiptsExplainer,
                  ),
                  enabled: false,
                  initialValue: false,
                  onToggle: (newVal) {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
