import 'package:acter/features/settings/widgets/in_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';

class SettingsInfoPage extends ConsumerWidget {
  const SettingsInfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InSettings(
      child: Scaffold(
        appBar: AppBar(title: const Text('App Info')),
        body: SettingsList(
          sections: [
            SettingsSection(
              title: const Text('App Defaults'),
              tiles: <SettingsTile>[
                SettingsTile(
                  title: const Text('Homeserver Name'),
                  value: const Text(defaultServerName),
                ),
                SettingsTile(
                  title: const Text('Homeserver URL'),
                  value: const Text(defaultServerUrl),
                ),
                SettingsTile(
                  title: const Text('Session Token Name'),
                  value: const Text(defaultSessionKey),
                ),
              ],
            ),
            SettingsSection(
              title: const Text('Debug Info'),
              tiles: <SettingsTile>[
                SettingsTile(
                  title: const Text('Version'),
                  value: const Text(versionName),
                ),
                SettingsTile(
                  title: const Text('Rageshake App Name'),
                  value: Text(appName),
                ),
                SettingsTile(
                  title: const Text('Rust Log Settings'),
                  value: const Text(logSettings),
                ),
              ],
            ),
            SettingsSection(
              title: const Text('3rd Party'),
              tiles: [
                SettingsTile.navigation(
                  title: const Text('Licenses'),
                  value: const Text('Built on the shoulders of giants'),
                  leading: const Icon(Atlas.list_file_thin),
                  onPressed: (context) =>
                      context.pushNamed(Routes.licenses.name),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
