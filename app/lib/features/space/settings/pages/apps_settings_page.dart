import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/space/actions/set_acter_feature.dart';
import 'package:acter/features/space/actions/update_feature_power_level.dart';
import 'package:acter/features/space/settings/widgets/space_settings_menu.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
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
    final settingsLoader = ref.watch(spaceAppSettingsProvider(spaceId));

    return WithSidebar(
      sidebar: SpaceSettingsMenu(spaceId: spaceId),
      child: settingsLoader.when(
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
                title: Text(L10n.of(context).updates),
                tiles: [
                  SettingsTile(
                    enabled: canEdit,
                    title: const Text('Required PowerLevel'),
                    description: const Text(
                      'Minimum power level required to post news updates',
                    ),
                    trailing:
                        currentPw != null ? Text(pwText) : Text(defaultDesc),
                    onPressed: (context) async =>
                        await updateFeatureLevelChange(
                      context,
                      maxPowerLevel,
                      currentPw,
                      space,
                      powerLevels,
                      powerLevels.newsKey(),
                      L10n.of(context).updates,
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
                    onPressed: (context) async =>
                        await updateFeatureLevelChange(
                      context,
                      maxPowerLevel,
                      currentPw,
                      space,
                      powerLevels,
                      powerLevels.pinsKey(),
                      L10n.of(context).pins,
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
                        await updateFeatureLevelChange(
                      context,
                      maxPowerLevel,
                      currentPw,
                      space,
                      powerLevels,
                      powerLevels.eventsKey(),
                      L10n.of(context).events,
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
                    onPressed: (context) async =>
                        await updateFeatureLevelChange(
                      context,
                      maxPowerLevel,
                      taskListCurrentPw,
                      space,
                      powerLevels,
                      powerLevels.taskListsKey(),
                      L10n.of(context).taskList,
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
                    onPressed: (context) async =>
                        await updateFeatureLevelChange(
                      context,
                      maxPowerLevel,
                      tasksCurrentPw,
                      space,
                      powerLevels,
                      powerLevels.tasksKey(),
                      L10n.of(context).tasks,
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

          return Scaffold(
            appBar: AppBar(
              title: const Text('Apps Settings'),
              automaticallyImplyLeading: !context.isLargeScreen,
            ),
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
                      onToggle: (newVal) async => await setActerFeature(
                        context,
                        newVal,
                        appSettings,
                        space,
                        SpaceFeature.updates,
                        L10n.of(context).updates,
                      ),
                    ),
                    SettingsTile.switchTile(
                      title: const Text('Pins'),
                      enabled: canEdit,
                      description: const Text('Pin important information'),
                      initialValue: pins.active(),
                      onToggle: (newVal) async => await setActerFeature(
                        context,
                        newVal,
                        appSettings,
                        space,
                        SpaceFeature.pins,
                        L10n.of(context).pins,
                      ),
                    ),
                    SettingsTile.switchTile(
                      title: const Text('Events Calendar'),
                      enabled: canEdit,
                      description: const Text('Calender with Events'),
                      initialValue: events.active(),
                      onToggle: (newVal) async => await setActerFeature(
                        context,
                        newVal,
                        appSettings,
                        space,
                        SpaceFeature.events,
                        L10n.of(context).event,
                      ),
                    ),
                    SettingsTile.switchTile(
                      title: const Text('Tasks'),
                      key: tasksSwitch,
                      enabled: canEdit,
                      description: const Text('ToDo-Lists & Tasks'),
                      initialValue: tasks.active(),
                      onToggle: (newVal) async => await setActerFeature(
                        context,
                        newVal,
                        appSettings,
                        space,
                        SpaceFeature.tasks,
                        L10n.of(context).tasks,
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
        error: (e, s) {
          _log.severe('Failed to load space settings', e, s);
          return Center(
            child: Text(L10n.of(context).loadingFailed(e)),
          );
        },
      ),
    );
  }
}
