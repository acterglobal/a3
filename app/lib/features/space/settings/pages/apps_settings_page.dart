import 'package:acter/common/extensions/acter_build_context.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
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
  if (pw == null) return 'None';
  return switch (pw) {
    100 => 'Admin',
    50 => 'Mod',
    0 => 'Regular',
    _ => 'Custom',
  };
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

  const SpaceAppsSettingsPage({
    super.key,
    required this.spaceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
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

          return Scaffold(
            appBar: AppBar(
              title: Text(lang.appSettings),
              automaticallyImplyLeading: !context.isLargeScreen,
            ),
            body: SettingsList(
              sections: [
                SettingsSection(
                  title: Text(lang.activeApps),
                  tiles: [
                    SettingsTile.switchTile(
                      title: Text(lang.boost),
                      enabled: canEdit,
                      description: Text(lang.postSpaceWiseBoost),
                      initialValue: news.active(),
                      onToggle: (newVal) => setActerFeature(
                        context,
                        newVal,
                        appSettings,
                        space,
                        SpaceFeature.boosts,
                        lang.boosts,
                      ),
                    ),
                    SettingsTile.switchTile(
                      title: Text(lang.pin),
                      enabled: canEdit,
                      description: Text(lang.pinImportantInformation),
                      initialValue: pins.active(),
                      onToggle: (newVal) => setActerFeature(
                        context,
                        newVal,
                        appSettings,
                        space,
                        SpaceFeature.pins,
                        lang.pins,
                      ),
                    ),
                    SettingsTile.switchTile(
                      title: Text(lang.events),
                      enabled: canEdit,
                      description: Text(lang.calenderWithEvents),
                      initialValue: events.active(),
                      onToggle: (newVal) => setActerFeature(
                        context,
                        newVal,
                        appSettings,
                        space,
                        SpaceFeature.events,
                        lang.event,
                      ),
                    ),
                    SettingsTile.switchTile(
                      title: Text(lang.tasks),
                      key: tasksSwitch,
                      enabled: canEdit,
                      description: Text(lang.taskList),
                      initialValue: tasks.active(),
                      onToggle: (newVal) => setActerFeature(
                        context,
                        newVal,
                        appSettings,
                        space,
                        SpaceFeature.tasks,
                        lang.tasks,
                      ),
                    ),
                  ],
                ),
                buildDefaultSection(
                  context,
                  powerLevels,
                  space,
                  maxPowerLevel,
                  canEdit,
                  defaultDesc,
                ),
                if (news.active())
                  buildNewsSection(
                    context,
                    powerLevels,
                    space,
                    maxPowerLevel,
                    canEdit,
                    defaultDesc,
                  ),
                if (pins.active())
                  buildPinsSection(
                    context,
                    powerLevels,
                    space,
                    maxPowerLevel,
                    canEdit,
                    defaultDesc,
                  ),
                if (events.active())
                  buildEventsSection(
                    context,
                    powerLevels,
                    space,
                    maxPowerLevel,
                    canEdit,
                    defaultDesc,
                  ),
                if (tasks.active())
                  buildTasksSection(
                    context,
                    powerLevels,
                    space,
                    maxPowerLevel,
                    canEdit,
                    defaultDesc,
                  ),
              ],
            ),
          );
        },
        loading: () => Center(
          child: Text(lang.loading),
        ),
        error: (e, s) {
          _log.severe('Failed to load space settings', e, s);
          return Center(
            child: Text(lang.loadingFailed(e)),
          );
        },
      ),
    );
  }

  SettingsSection buildDefaultSection(
    BuildContext context,
    RoomPowerLevels powerLevels,
    Space space,
    int maxPowerLevel,
    bool canEdit,
    String defaultDesc,
  ) {
    return SettingsSection(
      title: const Text('General Permissions'),
      tiles: [
        buildDefaultEventsTile(
          context,
          powerLevels,
          space,
          maxPowerLevel,
          canEdit,
          defaultDesc,
        ),
        buildDefaultInviteTile(
          context,
          powerLevels,
          space,
          maxPowerLevel,
          canEdit,
          defaultDesc,
        ),
        buildDefaultKickTile(
          context,
          powerLevels,
          space,
          maxPowerLevel,
          canEdit,
          defaultDesc,
        ),
        buildDefaultBanTile(
          context,
          powerLevels,
          space,
          maxPowerLevel,
          canEdit,
          defaultDesc,
        ),
        buildDefaultRedactTile(
          context,
          powerLevels,
          space,
          maxPowerLevel,
          canEdit,
          defaultDesc,
        ),
      ],
    );
  }

  SettingsTile buildDefaultEventsTile(
    BuildContext context,
    RoomPowerLevels powerLevels,
    Space space,
    int maxPowerLevel,
    bool canEdit,
    String defaultDesc,
  ) {
    final lang = L10n.of(context);
    final eventsDefaulLevel = powerLevels.eventsDefault();
    final pwTextTL = maxPowerLevel == 100
        ? powerLevelName(eventsDefaulLevel)
        : 'Custom ($eventsDefaulLevel)';

    return SettingsTile(
      enabled: canEdit,
      title: const Text('Required minimum level'),
      description: Text(lang.minPowerLevelError(lang.tasks)),
      trailing: Text(pwTextTL),
      onPressed: (context) => updateFeatureLevelChangeDialog(
        context,
        maxPowerLevel,
        powerLevels.eventsDefault(),
        space,
        powerLevels,
        'events_default',
        'Minimum level to interact',
        isGlobal: true,
      ),
    );
  }

  SettingsTile buildDefaultKickTile(
    BuildContext context,
    RoomPowerLevels powerLevels,
    Space space,
    int maxPowerLevel,
    bool canEdit,
    String defaultDesc,
  ) {
    final lang = L10n.of(context);
    final eventsDefaulLevel = powerLevels.kick();
    final pwTextTL = maxPowerLevel == 100
        ? powerLevelName(eventsDefaulLevel)
        : 'Custom ($eventsDefaulLevel)';

    return SettingsTile(
      enabled: canEdit,
      title: const Text('Kick Power Level'),
      description: Text(lang.minPowerLevelError(lang.tasks)),
      trailing: Text(pwTextTL),
      onPressed: (context) => updateFeatureLevelChangeDialog(
        context,
        maxPowerLevel,
        powerLevels.eventsDefault(),
        space,
        powerLevels,
        'kick',
        'Minimum level to kick',
        isGlobal: true,
      ),
    );
  }

  SettingsTile buildDefaultInviteTile(
    BuildContext context,
    RoomPowerLevels powerLevels,
    Space space,
    int maxPowerLevel,
    bool canEdit,
    String defaultDesc,
  ) {
    final lang = L10n.of(context);
    final eventsDefaulLevel = powerLevels.invite();
    final pwTextTL = maxPowerLevel == 100
        ? powerLevelName(eventsDefaulLevel)
        : 'Custom ($eventsDefaulLevel)';

    return SettingsTile(
      enabled: canEdit,
      title: const Text('Invite Power Level'),
      description: Text(lang.minPowerLevelError(lang.tasks)),
      trailing: Text(pwTextTL),
      onPressed: (context) => updateFeatureLevelChangeDialog(
        context,
        maxPowerLevel,
        powerLevels.eventsDefault(),
        space,
        powerLevels,
        'invite',
        'Minimum level to invite',
        isGlobal: true,
      ),
    );
  }

  SettingsTile buildDefaultRedactTile(
    BuildContext context,
    RoomPowerLevels powerLevels,
    Space space,
    int maxPowerLevel,
    bool canEdit,
    String defaultDesc,
  ) {
    final lang = L10n.of(context);
    final eventsDefaulLevel = powerLevels.redact();
    final pwTextTL = maxPowerLevel == 100
        ? powerLevelName(eventsDefaulLevel)
        : 'Custom ($eventsDefaulLevel)';

    return SettingsTile(
      enabled: canEdit,
      title: const Text('Redact Power Level'),
      description: Text(lang.minPowerLevelError(lang.tasks)),
      trailing: Text(pwTextTL),
      onPressed: (context) => updateFeatureLevelChangeDialog(
        context,
        maxPowerLevel,
        powerLevels.eventsDefault(),
        space,
        powerLevels,
        'redact',
        'Minimum level to redact',
        isGlobal: true,
      ),
    );
  }

  SettingsTile buildDefaultBanTile(
    BuildContext context,
    RoomPowerLevels powerLevels,
    Space space,
    int maxPowerLevel,
    bool canEdit,
    String defaultDesc,
  ) {
    final lang = L10n.of(context);
    final eventsDefaulLevel = powerLevels.ban();
    final pwTextTL = maxPowerLevel == 100
        ? powerLevelName(eventsDefaulLevel)
        : 'Custom ($eventsDefaulLevel)';

    return SettingsTile(
      enabled: canEdit,
      title: const Text('Ban Power Level'),
      description: Text(lang.minPowerLevelError(lang.tasks)),
      trailing: Text(pwTextTL),
      onPressed: (context) => updateFeatureLevelChangeDialog(
        context,
        maxPowerLevel,
        powerLevels.eventsDefault(),
        space,
        powerLevels,
        'ban',
        'Minimum level to ban',
        isGlobal: true,
      ),
    );
  }

  SettingsSection buildNewsSection(
    BuildContext context,
    RoomPowerLevels powerLevels,
    Space space,
    int maxPowerLevel,
    bool canEdit,
    String defaultDesc,
  ) {
    final lang = L10n.of(context);

    final currentPw = powerLevels.news();
    final pwText = maxPowerLevel == 100
        ? powerLevelName(currentPw)
        : 'Custom ($currentPw)';
    return SettingsSection(
      title: Text(lang.boosts),
      tiles: [
        SettingsTile(
          enabled: canEdit,
          title: Text(lang.requiredPowerLevel),
          description: Text(lang.minPowerLevelError(lang.boost)),
          trailing: Text(currentPw != null ? pwText : defaultDesc),
          onPressed: (context) => updateFeatureLevelChangeDialog(
            context,
            maxPowerLevel,
            currentPw,
            space,
            powerLevels,
            powerLevels.newsKey(),
            lang.boosts,
          ),
        ),
        SettingsTile.switchTile(
          title: Text(lang.commentsOnBoost),
          description: Text(lang.notYetSupported),
          enabled: false,
          initialValue: false,
          onToggle: (newVal) {},
        ),
      ],
    );
  }

  SettingsSection buildPinsSection(
    BuildContext context,
    RoomPowerLevels powerLevels,
    Space space,
    int maxPowerLevel,
    bool canEdit,
    String defaultDesc,
  ) {
    final lang = L10n.of(context);

    final currentPw = powerLevels.pins();
    final pwText = maxPowerLevel == 100
        ? powerLevelName(currentPw)
        : 'Custom ($currentPw)';
    return SettingsSection(
      title: Text(lang.pin),
      tiles: [
        SettingsTile(
          enabled: canEdit,
          title: Text(lang.requiredPowerLevel),
          description: Text(
            lang.minPowerLevelError(lang.pin),
          ),
          trailing: Text(currentPw != null ? pwText : defaultDesc),
          onPressed: (context) => updateFeatureLevelChangeDialog(
            context,
            maxPowerLevel,
            currentPw,
            space,
            powerLevels,
            powerLevels.pinsKey(),
            lang.pins,
          ),
        ),
        SettingsTile.switchTile(
          title: Text(lang.commentsOnPin),
          description: Text(lang.notYetSupported),
          enabled: false,
          initialValue: false,
          onToggle: (newVal) {},
        ),
      ],
    );
  }

  SettingsSection buildEventsSection(
    BuildContext context,
    RoomPowerLevels powerLevels,
    Space space,
    int maxPowerLevel,
    bool canEdit,
    String defaultDesc,
  ) {
    final lang = L10n.of(context);
    final currentPw = powerLevels.events();
    final pwText = maxPowerLevel == 100
        ? powerLevelName(currentPw)
        : 'Custom ($currentPw)';
    return SettingsSection(
      title: Text(lang.events),
      tiles: [
        SettingsTile(
          enabled: canEdit,
          title: Text(lang.adminPowerLevel),
          description: Text(
            lang.minPowerLevelError(lang.event),
          ),
          trailing: Text(currentPw != null ? pwText : defaultDesc),
          onPressed: (context) => updateFeatureLevelChangeDialog(
            context,
            maxPowerLevel,
            currentPw,
            space,
            powerLevels,
            powerLevels.eventsKey(),
            lang.events,
          ),
        ),
        SettingsTile(
          enabled: false,
          title: Text(lang.rsvpPowerLevel),
          description: Text(lang.minPowerLevelRsvp),
          trailing: Text(lang.notYetSupported),
        ),
        SettingsTile.switchTile(
          title: Text(lang.comments),
          description: Text(lang.notYetSupported),
          enabled: false,
          initialValue: false,
          onToggle: (newVal) {},
        ),
      ],
    );
  }

  SettingsSection buildTasksSection(
    BuildContext context,
    RoomPowerLevels powerLevels,
    Space space,
    int maxPowerLevel,
    bool canEdit,
    String defaultDesc,
  ) {
    final lang = L10n.of(context);

    final taskListCurrentPw = powerLevels.taskLists();
    final tasksCurrentPw = powerLevels.tasks();
    final pwTextTL = maxPowerLevel == 100
        ? powerLevelName(taskListCurrentPw)
        : 'Custom ($taskListCurrentPw)';
    final pwTextT = maxPowerLevel == 100
        ? powerLevelName(tasksCurrentPw)
        : 'Custom ($tasksCurrentPw)';
    return SettingsSection(
      title: Text(lang.tasks),
      tiles: [
        SettingsTile(
          enabled: canEdit,
          title: Text(lang.taskListPowerLevel),
          description: Text(lang.minPowerLevelError(lang.taskList)),
          trailing:
              taskListCurrentPw != null ? Text(pwTextTL) : Text(defaultDesc),
          onPressed: (context) => updateFeatureLevelChangeDialog(
            context,
            maxPowerLevel,
            taskListCurrentPw,
            space,
            powerLevels,
            powerLevels.taskListsKey(),
            lang.taskList,
          ),
        ),
        SettingsTile(
          enabled: canEdit,
          title: Text(lang.tasksPowerLevel),
          description: Text(lang.minPowerLevelError(lang.tasks)),
          trailing: tasksCurrentPw != null ? Text(pwTextT) : Text(defaultDesc),
          onPressed: (context) => updateFeatureLevelChangeDialog(
            context,
            maxPowerLevel,
            tasksCurrentPw,
            space,
            powerLevels,
            powerLevels.tasksKey(),
            lang.tasks,
          ),
        ),
        SettingsTile.switchTile(
          title: Text(lang.comments),
          description: Text(lang.notYetSupported),
          enabled: false,
          initialValue: false,
          onToggle: (newVal) {},
        ),
      ],
    );
  }
}
