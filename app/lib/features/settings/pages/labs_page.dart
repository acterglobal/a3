import 'package:acter/common/notifications/notifications.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
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
    return WithSidebar(
      sidebar: const SettingsMenu(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Acter Labs')),
        body: SettingsList(
          sections: [
            SettingsSection(
              title: const Text('Notifications'),
              tiles: [
                SettingsTile.switchTile(
                  title: const Text('Push Notifications'),
                  description: Text(
                    !supportedPlatforms
                        ? 'Only supported on mobile (iOS & Android) right now'
                        : 'Needs App restart to activate',
                  ),
                  initialValue: supportedPlatforms &&
                      ref.watch(
                        isActiveProvider(LabsFeature.showNotifications),
                      ),
                  enabled: supportedPlatforms,
                  onToggle: (newVal) {
                    updateFeatureState(
                      ref,
                      LabsFeature.showNotifications,
                      newVal,
                    );
                    if (newVal) {
                      customMsgSnackbar(
                        context,
                        'Push enabled. Please restart to activate',
                      );
                    }
                  },
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
                  initialValue: ref.watch(isActiveProvider(LabsFeature.events)),
                  onToggle: (newVal) =>
                      updateFeatureState(ref, LabsFeature.events, newVal),
                ),
                SettingsTile.switchTile(
                  title: const Text('Tasks'),
                  description:
                      const Text('Manage Tasks lists and ToDos together'),
                  initialValue: false,
                  onToggle: (newVal) =>
                      updateFeatureState(ref, LabsFeature.tasks, newVal),
                ),
                SettingsTile.switchTile(
                  title: const Text('Polls'),
                  description: const Text('Polls and Surveys'),
                  initialValue: ref.watch(isActiveProvider(LabsFeature.polls)),
                  onToggle: (newVal) =>
                      updateFeatureState(ref, LabsFeature.polls, newVal),
                  enabled: false,
                ),
                SettingsTile.switchTile(
                  title: const Text('CoBudget'),
                  description: const Text('Manage budgets cooperatively'),
                  initialValue: ref.watch(
                    isActiveProvider(LabsFeature.cobudget),
                  ),
                  onToggle: (newVal) =>
                      updateFeatureState(ref, LabsFeature.cobudget, newVal),
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
