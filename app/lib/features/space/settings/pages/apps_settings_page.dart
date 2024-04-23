import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';

import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter/features/space/settings/widgets/space_settings_menu.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:settings_ui/settings_ui.dart';

final _log = Logger('a3::space::settings::app_settings');

String powerLevelName(int? pw) {
  if (pw == null) {
    return 'None';
  }
  switch (pw) {
    case 100:
      return 'Admin';
    case 50:
      return 'Mod';
    case 0:
      return 'Regular';
    default:
      return 'Custom';
  }
}

class SettingsAndMembership {
  final Space space;
  final RoomPowerLevels powerLevels;
  final ActerAppSettings settings;
  final Member? member;

  const SettingsAndMembership(
    this.space,
    this.powerLevels,
    this.settings,
    this.member,
  );
}

final spaceAppSettingsProvider = FutureProvider.autoDispose
    .family<SettingsAndMembership, String>((ref, spaceId) async {
  final space = await ref.watch(spaceProvider(spaceId).future);
  return SettingsAndMembership(
    space,
    await space.powerLevels(),
    await space.appSettings(),
    await ref.watch(roomMembershipProvider(spaceId).future),
  );
});

class SpaceAppsSettingsPage extends ConsumerWidget {
  static const tasksSwitch = Key('space-settings-tasks');
  final String spaceId;

  const SpaceAppsSettingsPage({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaceSettingsWatcher = ref.watch(spaceAppSettingsProvider(spaceId));
    final provider = ref.watch(featuresProvider);
    bool isActive(f) => provider.isActive(f);

    return WithSidebar(
      sidebar: SpaceSettingsMenu(spaceId: spaceId),
      child: spaceSettingsWatcher.when(
        data: (appSettingsAndMembership) {
          final appSettings = appSettingsAndMembership.settings;
          final powerLevels = appSettingsAndMembership.powerLevels;
          final defaultPw = powerLevels.eventsDefault();
          final usersDefaultPw = powerLevels.usersDefault();
          final maxPowerLevel = powerLevels.maxPowerLevel();
          String defaultDesc = 'default';
          if (usersDefaultPw >= defaultPw) {
            defaultDesc = 'not set / everyone';
          } else {
            defaultDesc = 'default [everyone has $usersDefaultPw]';
          }
          final space = appSettingsAndMembership.space;
          final canEdit = appSettingsAndMembership.member
                  ?.canString('CanChangeAppSettings') ==
              true;

          final news = appSettings.news();
          final events = appSettings.events();
          final pins = appSettings.pins();
          final tasks = appSettings.tasks();

          final moreSections = [];
          final labActions = [];
          if (news.active()) {
            final currentPw = powerLevels.news();
            final pwText = maxPowerLevel == 100
                ? powerLevelName(currentPw)
                : 'Custom ($currentPw)';
            moreSections.add(
              SettingsSection(
                title: const Text('Updates'),
                tiles: [
                  SettingsTile(
                    enabled: canEdit,
                    title: const Text('Required PowerLevel'),
                    description: const Text(
                      'Minimum power level required to post news updates',
                    ),
                    trailing:
                        currentPw != null ? Text(pwText) : Text(defaultDesc),
                    onPressed: (context) async => await onNewsLevelChange(
                      context,
                      maxPowerLevel,
                      currentPw,
                      space,
                      powerLevels,
                    ),
                  ),
                  SettingsTile.switchTile(
                    title: const Text('Comments on Updates'),
                    description: const Text('not yet supported'),
                    enabled: false,
                    initialValue: false,
                    onToggle: (newVal) {},
                  ),
                ],
              ),
            );
          }
          if (pins.active()) {
            final currentPw = powerLevels.pins();
            final pwText = maxPowerLevel == 100
                ? powerLevelName(currentPw)
                : 'Custom ($currentPw)';
            moreSections.add(
              SettingsSection(
                title: const Text('Pin'),
                tiles: [
                  SettingsTile(
                    enabled: canEdit,
                    title: const Text('Required PowerLevel'),
                    description: const Text(
                      'Minimum power level required to post and edit pins',
                    ),
                    trailing:
                        currentPw != null ? Text(pwText) : Text(defaultDesc),
                    onPressed: (context) async => await onPinLevelChange(
                      context,
                      maxPowerLevel,
                      currentPw,
                      space,
                      powerLevels,
                    ),
                  ),
                  SettingsTile.switchTile(
                    title: const Text('Comments on Pins'),
                    description: const Text('not yet supported'),
                    enabled: false,
                    initialValue: false,
                    onToggle: (newVal) {},
                  ),
                ],
              ),
            );
          }
          if (events.active()) {
            final currentPw = powerLevels.events();
            final pwText = maxPowerLevel == 100
                ? powerLevelName(currentPw)
                : 'Custom ($currentPw)';
            moreSections.add(
              SettingsSection(
                title: const Text('Calendar Events'),
                tiles: [
                  SettingsTile(
                    enabled: canEdit,
                    title: const Text('Admin PowerLevel'),
                    description: const Text(
                      'Minimum power level required to post calendar events',
                    ),
                    trailing:
                        currentPw != null ? Text(pwText) : Text(defaultDesc),
                    onPressed: (context) async =>
                        await onCalendarEventLevelChange(
                      context,
                      maxPowerLevel,
                      currentPw,
                      space,
                      powerLevels,
                    ),
                  ),
                  SettingsTile(
                    enabled: false,
                    title: const Text('RSVP PowerLevel'),
                    description: const Text(
                      'Minimum power level to RSVP to calendar events',
                    ),
                    trailing: const Text('not yet implemented'),
                  ),
                  SettingsTile.switchTile(
                    title: const Text('Comments'),
                    description: const Text('not yet supported'),
                    enabled: false,
                    initialValue: false,
                    onToggle: (newVal) {},
                  ),
                ],
              ),
            );
          }

          if (isActive(LabsFeature.tasks)) {
            labActions.add(
              SettingsTile.switchTile(
                title: const Text('Tasks'),
                key: tasksSwitch,
                enabled: canEdit,
                description: const Text('ToDo-Lists & Tasks'),
                initialValue: tasks.active(),
                onToggle: (newVal) async => await onTaskToggle(
                  context,
                  tasks,
                  newVal,
                  appSettings,
                  space,
                ),
              ),
            );
            if (tasks.active()) {
              final taskListCurrentPw = powerLevels.taskLists();
              final tasksCurrentPw = powerLevels.tasks();
              final pwTextTL = maxPowerLevel == 100
                  ? powerLevelName(taskListCurrentPw)
                  : 'Custom ($taskListCurrentPw)';
              final pwTextT = maxPowerLevel == 100
                  ? powerLevelName(tasksCurrentPw)
                  : 'Custom ($tasksCurrentPw)';
              moreSections.add(
                SettingsSection(
                  title: const Text('Tasks'),
                  tiles: [
                    SettingsTile(
                      enabled: canEdit,
                      title: const Text('TaskList PowerLevel'),
                      description: const Text(
                        'Minimum power level required to create & manage task lists',
                      ),
                      trailing: taskListCurrentPw != null
                          ? Text(pwTextTL)
                          : Text(defaultDesc),
                      onPressed: (context) async => await onTaskListLevelChange(
                        context,
                        maxPowerLevel,
                        taskListCurrentPw,
                        space,
                        powerLevels,
                      ),
                    ),
                    SettingsTile(
                      enabled: canEdit,
                      title: const Text('Tasks PowerLevel'),
                      description: const Text(
                        'Minimum power level required to interact with tasks',
                      ),
                      trailing: tasksCurrentPw != null
                          ? Text(pwTextT)
                          : Text(defaultDesc),
                      onPressed: (context) async => await onTaskLevelChange(
                        context,
                        maxPowerLevel,
                        tasksCurrentPw,
                        space,
                        powerLevels,
                      ),
                    ),
                    SettingsTile.switchTile(
                      title: const Text('Comments'),
                      description: const Text('not yet supported'),
                      enabled: false,
                      initialValue: false,
                      onToggle: (newVal) {},
                    ),
                  ],
                ),
              );
            }
          }

          return Scaffold(
            appBar: AppBar(title: const Text('Apps Settings')),
            body: SettingsList(
              sections: [
                SettingsSection(
                  title: const Text('Active Apps'),
                  tiles: [
                    SettingsTile.switchTile(
                      title: const Text('Updates'),
                      enabled: canEdit,
                      description: const Text('Post space-wide updates'),
                      initialValue: news.active(),
                      onToggle: (newVal) async => await onNewsToggle(
                        context,
                        news,
                        newVal,
                        appSettings,
                        space,
                      ),
                    ),
                    SettingsTile.switchTile(
                      title: const Text('Pins'),
                      enabled: canEdit,
                      description: const Text('Pin important information'),
                      initialValue: pins.active(),
                      onToggle: (newVal) async => onPinToggle(
                        context,
                        pins,
                        newVal,
                        appSettings,
                        space,
                      ),
                    ),
                    SettingsTile.switchTile(
                      title: const Text('Events Calendar'),
                      enabled: canEdit,
                      description: const Text('Calender with Events'),
                      initialValue: events.active(),
                      onToggle: (newVal) async => await onCalendarEventToggle(
                        context,
                        events,
                        newVal,
                        appSettings,
                        space,
                      ),
                    ),
                    ...labActions,
                  ],
                ),
                ...moreSections,
              ],
            ),
          );
        },
        loading: () => const Center(child: Text('loading')),
        error: (e, s) => Center(
          child: Text('Error loading app settings: $e'),
        ),
      ),
    );
  }

  Future<void> onNewsLevelChange(
    BuildContext context,
    int maxPowerLevel,
    int? currentPw,
    Space space,
    RoomPowerLevels powerLevels,
  ) async {
    final newPowerLevel = await showDialog<int?>(
      context: context,
      builder: (BuildContext context) => ChangePowerLevel(
        featureName: 'Updates',
        currentPowerLevelName:
            maxPowerLevel == 100 ? powerLevelName(currentPw) : 'Custom',
        currentPowerLevel: currentPw,
      ),
    );
    if (newPowerLevel == currentPw) return;
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.show(status: L10n.of(context).changingPowerLevelOf('Updates'));
    try {
      await space.updateFeaturePowerLevels(
        powerLevels.newsKey(),
        newPowerLevel,
      );
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(L10n.of(context).powerLevelSubmitted('Updates'));
    } catch (e, st) {
      _log.severe('Failed to change power level of Updates', e, st);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).failedToChangePowerLevel(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> onNewsToggle(
    BuildContext context,
    NewsSettings news,
    bool newVal,
    ActerAppSettings appSettings,
    Space space,
  ) async {
    EasyLoading.show(status: L10n.of(context).changingSettingOf('Updates'));
    try {
      final updated = news.updater();
      updated.active(newVal);
      final builder = appSettings.updateBuilder();
      builder.news(updated.build());
      await space.updateAppSettings(builder);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(L10n.of(context).changedSettingOf('Updates'));
    } catch (e, st) {
      _log.severe('Failed to change setting of Updates', e, st);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).failedToToggleSettingOf('Updates', e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> onPinLevelChange(
    BuildContext context,
    int maxPowerLevel,
    int? currentPw,
    Space space,
    RoomPowerLevels powerLevels,
  ) async {
    final newPowerLevel = await showDialog<int?>(
      context: context,
      builder: (BuildContext context) => ChangePowerLevel(
        featureName: 'Pin',
        currentPowerLevelName:
            maxPowerLevel == 100 ? powerLevelName(currentPw) : 'Custom',
        currentPowerLevel: currentPw,
      ),
    );
    if (newPowerLevel == currentPw) return;
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.show(status: L10n.of(context).changingSettingOf('Pins'));
    try {
      await space.updateFeaturePowerLevels(
        powerLevels.pinsKey(),
        newPowerLevel,
      );
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(L10n.of(context).powerLevelSubmitted('Pins'));
    } catch (e, st) {
      _log.severe('Failed to change power level of Pins', e, st);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).failedToChangePowerLevel(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> onPinToggle(
    BuildContext context,
    PinsSettings pins,
    bool newVal,
    ActerAppSettings appSettings,
    Space space,
  ) async {
    EasyLoading.show(status: L10n.of(context).changingSettingOf('Pins'));
    try {
      final updated = pins.updater();
      updated.active(newVal);
      final builder = appSettings.updateBuilder();
      builder.pins(updated.build());
      await space.updateAppSettings(builder);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(L10n.of(context).changedSettingOf('Pins'));
    } catch (e, st) {
      _log.severe('Failed to change setting of Pins', e, st);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).failedToToggleSettingOf('Pins', e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> onCalendarEventLevelChange(
    BuildContext context,
    int maxPowerLevel,
    int? currentPw,
    Space space,
    RoomPowerLevels powerLevels,
  ) async {
    final newPowerLevel = await showDialog<int?>(
      context: context,
      builder: (BuildContext context) => ChangePowerLevel(
        featureName: 'Calendar Events',
        currentPowerLevelName:
            maxPowerLevel == 100 ? powerLevelName(currentPw) : 'Custom',
        currentPowerLevel: currentPw,
      ),
    );
    if (newPowerLevel == currentPw) return;
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.show(status: L10n.of(context).changingPowerLevelOf('Events'));
    try {
      await space.updateFeaturePowerLevels(
        powerLevels.eventsKey(),
        newPowerLevel,
      );
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(L10n.of(context).powerLevelSubmitted('Events'));
    } catch (e, st) {
      _log.severe('Failed to change power level of Events', e, st);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).failedToChangePowerLevel(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> onCalendarEventToggle(
    BuildContext context,
    EventsSettings events,
    bool newVal,
    ActerAppSettings appSettings,
    Space space,
  ) async {
    EasyLoading.show(status: L10n.of(context).changingSettingOf('Events'));
    try {
      final updated = events.updater();
      updated.active(newVal);
      final builder = appSettings.updateBuilder();
      builder.events(updated.build());
      await space.updateAppSettings(builder);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(L10n.of(context).changedSettingOf('Events'));
    } catch (e, st) {
      _log.severe('Failed to change setting of Events', e, st);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).failedToToggleSettingOf('Events', e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> onTaskListLevelChange(
    BuildContext context,
    int maxPowerLevel,
    int? currentPw,
    Space space,
    RoomPowerLevels powerLevels,
  ) async {
    final newPowerLevel = await showDialog<int?>(
      context: context,
      builder: (BuildContext context) => ChangePowerLevel(
        featureName: 'Task Lists',
        currentPowerLevelName:
            maxPowerLevel == 100 ? powerLevelName(currentPw) : 'Custom',
        currentPowerLevel: currentPw,
      ),
    );
    if (newPowerLevel == currentPw) return;
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.show(
      status: L10n.of(context).changingPowerLevelOf('Tasklists'),
    );
    try {
      await space.updateFeaturePowerLevels(
        powerLevels.taskListsKey(),
        newPowerLevel,
      );
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(L10n.of(context).powerLevelSubmitted('Tasklists'));
    } catch (e, st) {
      _log.severe('Failed to change power level of Tasklists', e, st);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).failedToChangePowerLevel(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> onTaskLevelChange(
    BuildContext context,
    int maxPowerLevel,
    int? currentPw,
    Space space,
    RoomPowerLevels powerLevels,
  ) async {
    final newPowerLevel = await showDialog<int?>(
      context: context,
      builder: (BuildContext context) => ChangePowerLevel(
        featureName: 'Tasks',
        currentPowerLevelName:
            maxPowerLevel == 100 ? powerLevelName(currentPw) : 'Custom',
        currentPowerLevel: currentPw,
      ),
    );
    if (newPowerLevel == currentPw) return;
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.show(status: L10n.of(context).changingPowerLevelOf('Updates'));
    try {
      await space.updateFeaturePowerLevels(
        powerLevels.tasksKey(),
        newPowerLevel,
      );
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(L10n.of(context).powerLevelSubmitted('Tasks'));
    } catch (e, st) {
      _log.severe('Failed to change power level of Tasks', e, st);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).failedToChangePowerLevel(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> onTaskToggle(
    BuildContext context,
    TasksSettings tasks,
    bool newVal,
    ActerAppSettings appSettings,
    Space space,
  ) async {
    EasyLoading.show(status: L10n.of(context).changingSettingOf('Tasks'));
    try {
      final updated = tasks.updater();
      updated.active(newVal);
      final builder = appSettings.updateBuilder();
      builder.tasks(updated.build());
      await space.updateAppSettings(builder);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(L10n.of(context).changedSettingOf('Tasks'));
    } catch (e, st) {
      _log.severe('Failed to change setting of Tasks', e, st);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).failedToToggleSettingOf('Tasks', e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}

class ChangePowerLevel extends StatefulWidget {
  final String featureName;
  final int? currentPowerLevel;
  final String currentPowerLevelName;

  const ChangePowerLevel({
    super.key,
    required this.featureName,
    required this.currentPowerLevelName,
    this.currentPowerLevel,
  });

  @override
  State<ChangePowerLevel> createState() => _ChangePowerLevelState();
}

class _ChangePowerLevelState extends State<ChangePowerLevel> {
  final TextEditingController dropDownMenuCtrl = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? currentMemberStatus;
  int? customValue;

  @override
  void initState() {
    super.initState();
    setState(() => currentMemberStatus = widget.currentPowerLevelName);
  }

  void _updateMembershipStatus(String? value) {
    if (mounted) {
      setState(() => currentMemberStatus = value);
    }
  }

  void _newCustomLevel(String? value) {
    if (mounted) {
      setState(() {
        if (value != null) {
          customValue = int.tryParse(value);
        } else {
          customValue = null;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberStatus = widget.currentPowerLevelName;
    final currentPowerLevel = widget.currentPowerLevel;
    return AlertDialog(
      title: const Text('Update Power level'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Change the power level of'),
            Text(widget.featureName),
            // Row(
            //   children: [
            currentPowerLevel != null
                ? Text('from $memberStatus ($currentPowerLevel) to ')
                : const Text('from default to'),
            Padding(
              padding: const EdgeInsets.all(5),
              child: DropdownButtonFormField(
                value: currentMemberStatus,
                onChanged: _updateMembershipStatus,
                items: const [
                  DropdownMenuItem(
                    value: 'Admin',
                    child: Text('Admin'),
                  ),
                  DropdownMenuItem(
                    value: 'Mod',
                    child: Text('Moderator'),
                  ),
                  DropdownMenuItem(
                    value: 'Regular',
                    child: Text('Regular'),
                  ),
                  DropdownMenuItem(
                    value: 'None',
                    child: Text('None'),
                  ),
                  DropdownMenuItem(
                    value: 'Custom',
                    child: Text('Custom'),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: currentMemberStatus == 'Custom',
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: TextFormField(
                  decoration: const InputDecoration(
                    hintText: 'any number',
                    labelText: 'Custom power level',
                  ),
                  onChanged: _newCustomLevel,
                  initialValue: currentPowerLevel.toString(),
                  keyboardType:
                      const TextInputType.numberWithOptions(signed: true),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ], // Only numbers
                  validator: (String? value) {
                    return currentMemberStatus == 'Custom' &&
                            (value == null || int.tryParse(value) == null)
                        ? 'You need to enter the custom value as a number.'
                        : null;
                  },
                ),
              ),
            ),
          ],
          //   ),
          // ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: <Widget>[
        OutlinedButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
        OutlinedButton(
          onPressed: onUnset,
          child: const Text('Unset'),
        ),
        ActerPrimaryActionButton(
          onPressed: onSubmit,
          child: const Text('Submit'),
        ),
      ],
    );
  }

  void onCancel() {
    Navigator.pop(context, widget.currentPowerLevel);
  }

  void onUnset() {
    Navigator.pop(context, null);
  }

  void onSubmit() {
    if (!_formKey.currentState!.validate()) return;
    final freshMemberStatus = widget.currentPowerLevelName;
    if (freshMemberStatus == currentMemberStatus) {
      // nothing to do, all the same.
      Navigator.pop(context, null);
      return;
    }
    int? newValue;
    if (currentMemberStatus == 'Admin') {
      newValue = 100;
    } else if (currentMemberStatus == 'Mod') {
      newValue = 50;
    } else if (currentMemberStatus == 'Regular') {
      newValue = 0;
    } else {
      newValue = customValue ?? 0;
    }

    if (widget.currentPowerLevel == newValue) {
      // nothing to be done.
      newValue = null;
    }

    Navigator.pop(context, newValue);
  }
}
