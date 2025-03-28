import 'package:acter/common/extensions/acter_build_context.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:acter/features/settings/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:acter/common/widgets/typing_indicator.dart';

class SettingsLabsPage extends ConsumerWidget {
  static Key tasksLabSwitch = const Key('labs-tasks');
  static Key pinsEditorLabSwitch = const Key('labs-pins-editor');

  const SettingsLabsPage({super.key});

  String _getModeDescription(TypingIndicatorMode mode) {
    switch (mode) {
      case TypingIndicatorMode.name:
        return 'Show only names';
      case TypingIndicatorMode.avatar:
        return 'Show only avatars';
      case TypingIndicatorMode.nameAndAvatar:
        return 'Show both names and avatars';
    }
  }

  Future<void> _setTypingIndicatorMode(
    WidgetRef ref,
    TypingIndicatorMode mode,
  ) async {
    // First disable all modes
    await updateFeatureState(ref, LabsFeature.typingIndicatorName, false);
    await updateFeatureState(ref, LabsFeature.typingIndicatorAvatar, false);
    await updateFeatureState(
      ref,
      LabsFeature.typingIndicatorNameAndAvatar,
      false,
    );

    // Then enable the selected mode
    switch (mode) {
      case TypingIndicatorMode.name:
        await updateFeatureState(ref, LabsFeature.typingIndicatorName, true);
        break;
      case TypingIndicatorMode.avatar:
        await updateFeatureState(ref, LabsFeature.typingIndicatorAvatar, true);
        break;
      case TypingIndicatorMode.nameAndAvatar:
        await updateFeatureState(
          ref,
          LabsFeature.typingIndicatorNameAndAvatar,
          true,
        );
        break;
    }
  }

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
                SettingsTile.switchTile(
                  title: Text(lang.encryptionBackupKeyBackup),
                  description: Text(lang.sharedCalendarAndEvents),
                  initialValue: ref.watch(
                    isActiveProvider(LabsFeature.encryptionBackup),
                  ),
                  onToggle:
                      (newVal) async => await updateFeatureState(
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
                  initialValue: ref.watch(
                    isActiveProvider(LabsFeature.chatUnread),
                  ),
                  onToggle:
                      (newVal) => updateFeatureState(
                        ref,
                        LabsFeature.chatUnread,
                        newVal,
                      ),
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
                SettingsTile(
                  title: Text('Typing Indicator Style (Next Generation Chat)'),
                  description: Text(
                    _getModeDescription(
                      ref.watch(chatTypingIndicatorModeProvider),
                    ),
                  ),
                  trailing: PopupMenuButton<TypingIndicatorMode>(
                    onSelected: (mode) => _setTypingIndicatorMode(ref, mode),
                    itemBuilder:
                        (context) =>
                            TypingIndicatorMode.values.map((mode) {
                              return PopupMenuItem(
                                value: mode,
                                child: Text(_getModeDescription(mode)),
                              );
                            }).toList(),
                  ),
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
                  onToggle:
                      (newVal) =>
                          updateFeatureState(ref, LabsFeature.polls, newVal),
                  enabled: false,
                ),
                SettingsTile.switchTile(
                  title: Text(lang.coBudget),
                  description: Text(lang.manageBudgetsCooperatively),
                  initialValue: ref.watch(
                    isActiveProvider(LabsFeature.cobudget),
                  ),
                  onToggle:
                      (newVal) =>
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
