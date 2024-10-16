import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/calendar_sync/calendar_sync.dart';
import 'package:acter/features/settings/pages/settings_page.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter/features/settings/widgets/labs_notifications_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsLabsPage extends ConsumerWidget {
  static Key tasksLabSwitch = const Key('labs-tasks');
  static Key pinsEditorLabSwitch = const Key('labs-pins-editor');

  const SettingsLabsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return WithSidebar(
      sidebar: const SettingsPage(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(lang.labs),
          automaticallyImplyLeading: !context.isLargeScreen,
        ),
        body: SettingsList(
          sections: [
            SettingsSection(
              title: Text(lang.labsAppFeatures),
              tiles: [
                const LabsNotificationsSettingsTile(),
                SettingsTile.switchTile(
                  title: Text(lang.encryptionBackupKeyBackup),
                  description: Text(lang.sharedCalendarAndEvents),
                  initialValue:
                      ref.watch(isActiveProvider(LabsFeature.encryptionBackup)),
                  onToggle: (newVal) async => await updateFeatureState(
                    ref,
                    LabsFeature.encryptionBackup,
                    newVal,
                  ),
                ),
              ],
            ),
            SettingsSection(
              title: Text(lang.spaces),
              tiles: [
                SettingsTile.switchTile(
                  title: Text(lang.encryptedSpace),
                  description: Text(lang.notYetSupported),
                  enabled: false,
                  initialValue: false,
                  onToggle: (newVal) {},
                ),
              ],
            ),
            SettingsSection(
              title: Text(lang.chat),
              tiles: [
                SettingsTile.switchTile(
                  title: Text(lang.unreadMarkerFeatureTitle),
                  description: Text(lang.unreadMarkerFeatureDescription),
                  initialValue:
                      ref.watch(isActiveProvider(LabsFeature.chatUnread)),
                  onToggle: (newVal) =>
                      updateFeatureState(ref, LabsFeature.chatUnread, newVal),
                ),
                SettingsTile.switchTile(
                  title: Text(L10n.of(context).chatNG),
                  description: Text(L10n.of(context).chatNGExplainer),
                  initialValue: ref.watch(isActiveProvider(LabsFeature.chatNG)),
                  onToggle: (newVal) {
                    updateFeatureState(ref, LabsFeature.chatNG, newVal);
                    EasyLoading.showToast(
                      'Changes will affect after app restart',
                    );
                  },
                ),
              ],
            ),
            SettingsSection(
              title: Text(lang.calendar),
              tiles: [
                SettingsTile.switchTile(
                  enabled: isSupportedPlatform,
                  title: Text(lang.calendarSyncFeatureTitle),
                  description: Text(lang.calendarSyncFeatureDesc),
                  initialValue: isSupportedPlatform &&
                      ref.watch(
                        isActiveProvider(LabsFeature.deviceCalendarSync),
                      ),
                  onToggle: (newVal) async {
                    await updateFeatureState(
                      ref,
                      LabsFeature.deviceCalendarSync,
                      newVal,
                    );
                    if (newVal) {
                      await initCalendarSync(ignoreRejection: true);
                      EasyLoading.showToast('Acter Calendars synced');
                    } else {
                      await clearActerCalendars();
                      EasyLoading.showToast('Acter Calendars removes');
                    }
                  },
                ),
              ],
            ),
            SettingsSection(
              title: Text(lang.apps),
              tiles: [
                SettingsTile.switchTile(
                  title: Text(lang.polls),
                  description: Text(lang.pollsAndSurveys),
                  initialValue: ref.watch(isActiveProvider(LabsFeature.polls)),
                  onToggle: (newVal) =>
                      updateFeatureState(ref, LabsFeature.polls, newVal),
                  enabled: false,
                ),
                SettingsTile.switchTile(
                  title: Text(lang.coBudget),
                  description: Text(lang.manageBudgetsCooperatively),
                  initialValue:
                      ref.watch(isActiveProvider(LabsFeature.cobudget)),
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
