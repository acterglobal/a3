import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/settings/widgets/settings_menu.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsLabsPage extends ConsumerWidget {
  const SettingsLabsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(featuresProvider);
    bool isActive(f) => provider.isActive(f);
    bool updateFeatureState(f, value) {
      debugPrint('setting $f to $value');
      ref.read(featuresProvider.notifier).setActive(f, value);
      return value;
    }

    return WithSidebar(
      sidebar: const SettingsMenu(),
      child: Scaffold(
        appBar: AppBar(title: const Text('App Labs')),
        body: SettingsList(
          sections: [
            SettingsSection(
              title: const Text('Notifications'),
              tiles: [
                SettingsTile.switchTile(
                  title: const Text('Show Notifications'),
                  description: const Text(
                    'Only supported on Linux, iOS and Android right now',
                  ),
                  initialValue: isActive(LabsFeature.showNotifications),
                  onToggle: (newVal) =>
                      updateFeatureState(LabsFeature.showNotifications, newVal),
                ),
              ],
            ),
            SettingsSection(
              title: const Text('Spaces'),
              tiles: [
                SettingsTile.switchTile(
                  title: const Text('Encrypted spaces'),
                  description: const Text('not yet supported'),
                  enabled: false,
                  initialValue: false,
                  onToggle: (newVal) {},
                ),
              ],
            ),
            SettingsSection(
              title: const Text('Apps'),
              tiles: [
                SettingsTile.switchTile(
                  title: const Text('Events'),
                  description: const Text('Shared Calendar and events'),
                  initialValue: isActive(LabsFeature.events),
                  onToggle: (newVal) =>
                      updateFeatureState(LabsFeature.events, newVal),
                ),
                SettingsTile.switchTile(
                  title: const Text('Tasks'),
                  enabled: false,
                  description:
                      const Text('Manage Tasks lists and ToDos together'),
                  initialValue: false,
                  onToggle: (newVal) =>
                      updateFeatureState(LabsFeature.tasks, newVal),
                ),
                SettingsTile.switchTile(
                  title: const Text('Polls'),
                  description: const Text('Polls and Surveys'),
                  initialValue: isActive(LabsFeature.polls),
                  onToggle: (newVal) =>
                      updateFeatureState(LabsFeature.polls, newVal),
                  enabled: false,
                ),
                SettingsTile.switchTile(
                  title: const Text('CoBudget'),
                  description: const Text('Manage budgets cooperatively'),
                  initialValue: isActive(LabsFeature.cobudget),
                  onToggle: (newVal) =>
                      updateFeatureState(LabsFeature.cobudget, newVal),
                  enabled: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
