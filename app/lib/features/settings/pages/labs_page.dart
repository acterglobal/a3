import 'package:acter/features/settings/widgets/in_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:acter/features/settings/providers/labs_features.dart';

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

    return InSettings(
      child: Scaffold(
        appBar: AppBar(title: const Text('App Labs')),
        body: SettingsList(
          sections: [
            SettingsSection(
              title: const Text('Apps'),
              tiles: [
                SettingsTile.switchTile(
                  title: const Text('Tasks'),
                  description:
                      const Text('Manage Tasks lists and Todos together'),
                  initialValue: isActive(LabsFeature.tasks),
                  onToggle: (newVal) =>
                      updateFeatureState(LabsFeature.tasks, newVal),
                ),
                SettingsTile.switchTile(
                  title: const Text('Events'),
                  description: const Text('Shared Calendar and events'),
                  initialValue: isActive(LabsFeature.events),
                  onToggle: (newVal) =>
                      updateFeatureState(LabsFeature.events, newVal),
                ),
                SettingsTile.switchTile(
                  title: const Text('Pins'),
                  description: const Text('Pins'),
                  initialValue: isActive(LabsFeature.pins),
                  onToggle: (newVal) =>
                      updateFeatureState(LabsFeature.pins, newVal),
                  enabled: false,
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
            SettingsSection(
              title: const Text('Search'),
              tiles: [
                SettingsTile.switchTile(
                  title: const Text('Search Spaces'),
                  description: const Text('Include spaces in search'),
                  initialValue: isActive(LabsFeature.searchSpaces),
                  onToggle: (newVal) =>
                      updateFeatureState(LabsFeature.searchSpaces, newVal),
                ),
              ],
            ),
            SettingsSection(
              title: const Text('Tasks'),
              tiles: [
                SettingsTile.switchTile(
                  title: const Text('CoBudget'),
                  description: const Text('Manage budgets cooperatively'),
                  initialValue: false,
                  onToggle: (newVal) => {},
                  enabled: isActive(LabsFeature.tasks),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
