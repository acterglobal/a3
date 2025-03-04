import 'package:acter/common/extensions/acter_build_context.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/space/actions/set_acter_feature.dart';
import 'package:acter/features/space/actions/update_feature_power_level.dart';
import 'package:acter/features/space/settings/widgets/space_settings_menu.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
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

  const SpaceAppsSettingsPage({super.key, required this.spaceId});

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
          final canEdit =
              appSettingsAndMembership.member?.canString(
                'CanChangeAppSettings',
              ) ==
              true;

          final news = appSettings.news();
          final stories = appSettings.stories();
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
                      onToggle:
                          (newVal) => setActerFeature(
                            context,
                            newVal,
                            appSettings,
                            space,
                            SpaceFeature.boosts,
                            lang.boosts,
                          ),
                    ),
                    SettingsTile.switchTile(
                      title: Text(lang.stories),
                      enabled: canEdit,
                      description: Text(lang.postSpaceWiseStories),
                      initialValue: stories.active(),
                      onToggle:
                          (newVal) => setActerFeature(
                            context,
                            newVal,
                            appSettings,
                            space,
                            SpaceFeature.stories,
                            lang.stories,
                          ),
                    ),
                    SettingsTile.switchTile(
                      title: Text(lang.pin),
                      enabled: canEdit,
                      description: Text(lang.pinImportantInformation),
                      initialValue: pins.active(),
                      onToggle:
                          (newVal) => setActerFeature(
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
                      onToggle:
                          (newVal) => setActerFeature(
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
                      onToggle:
                          (newVal) => setActerFeature(
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
                if (stories.active())
                  buildStoriesSection(
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
        loading: () => Center(child: Text(lang.loading)),
        error: (e, s) {
          _log.severe('Failed to load space settings', e, s);
          return Center(child: Text(lang.loadingFailed(e)));
        },
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
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
      title: Text(L10n.of(context).powerLevelsTitle),
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
        buildCommentsTile(
          context,
          powerLevels,
          space,
          maxPowerLevel,
          canEdit,
          defaultDesc,
        ),
        buildAttachmentsTile(
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
    final currentLevel = powerLevels.eventsDefault();
    final pwTextTL =
        maxPowerLevel == 100
            ? powerLevelName(currentLevel)
            : 'Custom ($currentLevel)';

    return SettingsTile(
      enabled: canEdit,
      title: Text(lang.powerLevelPostEventsTitle),
      description: Text(lang.powerLevelPostEventsDesc),
      trailing: Text(pwTextTL),
      onPressed:
          (context) => updateFeatureLevelChangeDialog(
            context,
            maxPowerLevel,
            currentLevel,
            space,
            powerLevels,
            'events_default',
            lang.powerLevelPostEventsTitle,
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
    final currentLevel = powerLevels.kick();
    final pwTextTL =
        maxPowerLevel == 100
            ? powerLevelName(currentLevel)
            : 'Custom ($currentLevel)';

    return SettingsTile(
      enabled: canEdit,
      title: Text(lang.powerLevelKickTitle),
      description: Text(lang.powerLevelKickDesc),
      trailing: Text(pwTextTL),
      onPressed:
          (context) => updateFeatureLevelChangeDialog(
            context,
            maxPowerLevel,
            currentLevel,
            space,
            powerLevels,
            'kick',
            lang.powerLevelKickTitle,
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
    final currentLevel = powerLevels.invite();
    final pwTextTL =
        maxPowerLevel == 100
            ? powerLevelName(currentLevel)
            : 'Custom ($currentLevel)';

    return SettingsTile(
      enabled: canEdit,
      title: Text(lang.powerLevelInviteTitle),
      description: Text(lang.powerLevelInviteDesc),
      trailing: Text(pwTextTL),
      onPressed:
          (context) => updateFeatureLevelChangeDialog(
            context,
            maxPowerLevel,
            currentLevel,
            space,
            powerLevels,
            'invite',
            lang.powerLevelInviteTitle,
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
    final currentLevel = powerLevels.redact();
    final pwTextTL =
        maxPowerLevel == 100
            ? powerLevelName(currentLevel)
            : 'Custom ($currentLevel)';

    return SettingsTile(
      enabled: canEdit,
      title: Text(lang.powerLevelRedactTitle),
      description: Text(lang.powerLevelRedactDesc),
      trailing: Text(pwTextTL),
      onPressed:
          (context) => updateFeatureLevelChangeDialog(
            context,
            maxPowerLevel,
            currentLevel,
            space,
            powerLevels,
            'redact',
            lang.powerLevelRedactTitle,
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
    final currentLevel = powerLevels.ban();
    final pwTextTL =
        maxPowerLevel == 100
            ? powerLevelName(currentLevel)
            : 'Custom ($currentLevel)';

    return SettingsTile(
      enabled: canEdit,
      title: Text(lang.powerLevelBanTitle),
      description: Text(lang.powerLevelBanDesc),
      trailing: Text(pwTextTL),
      onPressed:
          (context) => updateFeatureLevelChangeDialog(
            context,
            maxPowerLevel,
            currentLevel,
            space,
            powerLevels,
            'ban',
            lang.powerLevelBanDesc,
            isGlobal: true,
          ),
    );
  }

  SettingsTile buildCommentsTile(
    BuildContext context,
    RoomPowerLevels powerLevels,
    Space space,
    int maxPowerLevel,
    bool canEdit,
    String defaultDesc,
  ) {
    final lang = L10n.of(context);
    final powerLevel = powerLevels.comments();
    final pwTextTL =
        maxPowerLevel == 100
            ? powerLevelName(powerLevel)
            : 'Custom ($powerLevel)';

    return SettingsTile(
      enabled: canEdit,
      title: Text(lang.comments),
      description: Text(lang.minPowerLevelDesc(lang.comments)),
      trailing: Text(pwTextTL),
      onPressed:
          (context) => updateFeatureLevelChangeDialog(
            context,
            maxPowerLevel,
            powerLevel,
            space,
            powerLevels,
            powerLevels.commentsKey(),
            lang.minPowerLevelDesc(lang.comments),
            isGlobal: false,
          ),
    );
  }

  SettingsTile buildAttachmentsTile(
    BuildContext context,
    RoomPowerLevels powerLevels,
    Space space,
    int maxPowerLevel,
    bool canEdit,
    String defaultDesc,
  ) {
    final lang = L10n.of(context);
    final powerLevel = powerLevels.attachments();
    final pwTextTL =
        maxPowerLevel == 100
            ? powerLevelName(powerLevel)
            : 'Custom ($powerLevel)';

    return SettingsTile(
      enabled: canEdit,
      title: Text(lang.attachments),
      description: Text(lang.minPowerLevelDesc(lang.attachments)),
      trailing: Text(pwTextTL),
      onPressed:
          (context) => updateFeatureLevelChangeDialog(
            context,
            maxPowerLevel,
            powerLevel,
            space,
            powerLevels,
            powerLevels.attachmentsKey(),
            lang.minPowerLevelDesc(lang.attachments),
            isGlobal: false,
          ),
    );
  }

  SettingsTile buildRsvpTile(
    BuildContext context,
    RoomPowerLevels powerLevels,
    Space space,
    int maxPowerLevel,
    bool canEdit,
    String defaultDesc,
  ) {
    final lang = L10n.of(context);
    final powerLevel = powerLevels.rsvp();
    final pwTextTL =
        maxPowerLevel == 100
            ? powerLevelName(powerLevel)
            : 'Custom ($powerLevel)';

    return SettingsTile(
      enabled: canEdit,
      title: Text(lang.rsvpPowerLevel),
      description: Text(lang.minPowerLevelDesc(lang.rsvp)),
      trailing: Text(pwTextTL),
      onPressed:
          (context) => updateFeatureLevelChangeDialog(
            context,
            maxPowerLevel,
            powerLevel,
            space,
            powerLevels,
            powerLevels.rsvpKey(),
            lang.minPowerLevelDesc(lang.rsvp),
            isGlobal: false,
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
    final pwText =
        maxPowerLevel == 100
            ? powerLevelName(currentPw)
            : 'Custom ($currentPw)';
    return SettingsSection(
      title: Text(lang.boosts),
      tiles: [
        SettingsTile(
          enabled: canEdit,
          title: Text(lang.requiredPowerLevel),
          description: Text(lang.minPowerLevelDesc(lang.boost)),
          trailing: Text(currentPw != null ? pwText : defaultDesc),
          onPressed:
              (context) => updateFeatureLevelChangeDialog(
                context,
                maxPowerLevel,
                currentPw,
                space,
                powerLevels,
                powerLevels.newsKey(),
                lang.boosts,
              ),
        ),
      ],
    );
  }

  SettingsSection buildStoriesSection(
    BuildContext context,
    RoomPowerLevels powerLevels,
    Space space,
    int maxPowerLevel,
    bool canEdit,
    String defaultDesc,
  ) {
    final lang = L10n.of(context);

    final currentPw = powerLevels.news();
    final pwText =
        maxPowerLevel == 100
            ? powerLevelName(currentPw)
            : 'Custom ($currentPw)';
    return SettingsSection(
      title: Text(lang.stories),
      tiles: [
        SettingsTile(
          enabled: canEdit,
          title: Text(lang.requiredPowerLevel),
          description: Text(lang.minPowerLevelDesc(lang.stories)),
          trailing: Text(currentPw != null ? pwText : defaultDesc),
          onPressed:
              (context) => updateFeatureLevelChangeDialog(
                context,
                maxPowerLevel,
                currentPw,
                space,
                powerLevels,
                powerLevels.storiesKey(),
                lang.stories,
              ),
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
    final pwText =
        maxPowerLevel == 100
            ? powerLevelName(currentPw)
            : 'Custom ($currentPw)';
    return SettingsSection(
      title: Text(lang.pin),
      tiles: [
        SettingsTile(
          enabled: canEdit,
          title: Text(lang.requiredPowerLevel),
          description: Text(lang.minPowerLevelDesc(lang.pin)),
          trailing: Text(currentPw != null ? pwText : defaultDesc),
          onPressed:
              (context) => updateFeatureLevelChangeDialog(
                context,
                maxPowerLevel,
                currentPw,
                space,
                powerLevels,
                powerLevels.pinsKey(),
                lang.pins,
              ),
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
    final pwText =
        maxPowerLevel == 100
            ? powerLevelName(currentPw)
            : 'Custom ($currentPw)';
    return SettingsSection(
      title: Text(lang.events),
      tiles: [
        SettingsTile(
          enabled: canEdit,
          title: Text(lang.adminPowerLevel),
          description: Text(lang.minPowerLevelDesc(lang.event)),
          trailing: Text(currentPw != null ? pwText : defaultDesc),
          onPressed:
              (context) => updateFeatureLevelChangeDialog(
                context,
                maxPowerLevel,
                currentPw,
                space,
                powerLevels,
                powerLevels.eventsKey(),
                lang.events,
              ),
        ),
        buildRsvpTile(
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
    final pwTextTL =
        maxPowerLevel == 100
            ? powerLevelName(taskListCurrentPw)
            : 'Custom ($taskListCurrentPw)';
    final pwTextT =
        maxPowerLevel == 100
            ? powerLevelName(tasksCurrentPw)
            : 'Custom ($tasksCurrentPw)';
    return SettingsSection(
      title: Text(lang.tasks),
      tiles: [
        SettingsTile(
          enabled: canEdit,
          title: Text(lang.taskListPowerLevel),
          description: Text(lang.minPowerLevelDesc(lang.taskList)),
          trailing:
              taskListCurrentPw != null ? Text(pwTextTL) : Text(defaultDesc),
          onPressed:
              (context) => updateFeatureLevelChangeDialog(
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
          description: Text(lang.minPowerLevelDesc(lang.tasks)),
          trailing: tasksCurrentPw != null ? Text(pwTextT) : Text(defaultDesc),
          onPressed:
              (context) => updateFeatureLevelChangeDialog(
                context,
                maxPowerLevel,
                tasksCurrentPw,
                space,
                powerLevels,
                powerLevels.tasksKey(),
                lang.tasks,
              ),
        ),
      ],
    );
  }
}
