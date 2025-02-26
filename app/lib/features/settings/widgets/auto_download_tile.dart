import 'package:acter/features/settings/providers/app_settings_provider.dart';
import 'package:acter/features/settings/widgets/options_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::settings::chat_settings::auto_download');

class AutoDownloadTile extends ConsumerWidget {
  const AutoDownloadTile({super.key});

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
