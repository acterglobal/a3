import 'package:acter/features/settings/widgets/in_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:acter/main/routing/routes.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';

class SettingsLabsPage extends ConsumerWidget {
  const SettingsLabsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InSettings(
      child: Scaffold(
        appBar: AppBar(title: const Text('App Labs')),
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
              title: const Text('Apps'),
              tiles: [
                SettingsTile.switchTile(
                  title: const Text('Tasks'),
                  description:
                      const Text('Manage Tasks lists and Todos together'),
                  initialValue: false,
                  onToggle: (newVal) {},
                ),
                SettingsTile.switchTile(
                  title: const Text('Events'),
                  description: const Text('Shared Calendar and events'),
                  initialValue: false,
                  enabled: false,
                  onToggle: (newVal) {},
                ),
                SettingsTile.switchTile(
                  title: const Text('Polls'),
                  description: const Text('Polls and Surveys'),
                  initialValue: false,
                  enabled: false,
                  onToggle: (newVal) {},
                ),
                SettingsTile.switchTile(
                  title: const Text('CoBudget'),
                  description: const Text('Manage budgets cooperatively'),
                  initialValue: false,
                  enabled: false,
                  onToggle: (newVal) {},
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
