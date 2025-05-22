import 'package:acter/common/extensions/acter_build_context.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/router/routes.dart';
import 'package:acter/features/calendar_sync/actions/set_room_sync_preference.dart';
import 'package:acter/features/calendar_sync/providers/calendar_sync_active_provider.dart';
import 'package:acter/features/calendar_sync/providers/events_to_sync_provider.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:settings_ui/settings_ui.dart';

const defaultSpaceSettingsMenuKey = Key('space-settings-menu');

class SpaceSettingsMenu extends ConsumerWidget {
  static const appsMenu = Key('space-settings-apps');

  final bool isFullPage;
  final String spaceId;

  const SpaceSettingsMenu({
    required this.spaceId,
    this.isFullPage = false,
    super.key = defaultSpaceSettingsMenuKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final spaceAvatarInfo = ref.watch(roomAvatarInfoProvider(spaceId));
    final parentBadges =
        ref.watch(parentAvatarInfosProvider(spaceId)).valueOrNull;
    final curNotifStatus =
        ref.watch(roomNotificationStatusProvider(spaceId)).valueOrNull;

    final spaceName = spaceAvatarInfo.displayName ?? spaceId;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: isFullPage,
        leading:
            !isFullPage
                ? InkWell(
                  child: const Icon(Icons.close),
                  onTap: () {
                    context.pop();
                    context.pop();
                  },
                )
                : null,
        title: FittedBox(
          fit: BoxFit.fitWidth,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ActerAvatar(
                options: AvatarOptions(
                  AvatarInfo(
                    uniqueId: spaceId,
                    displayName: spaceAvatarInfo.displayName,
                    avatar: spaceAvatarInfo.avatar,
                  ),
                  parentBadges: parentBadges,
                  badgesSize: 18,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lang.settings),
                  Text(
                    '($spaceName)',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SettingsList(
            sections: [
              SettingsSection(
                title: Text(lang.personalSettings),
                tiles: [
                  SettingsTile(
                    key: appsMenu,
                    title: Text(lang.notificationsOverwrites),
                    description: Text(lang.notificationsOverwritesDescription),
                    leading: Icon(
                      curNotifStatus == 'muted'
                          ? Atlas.bell_dash_bold
                          : Atlas.bell_thin,
                      size: 18,
                    ),
                    onPressed: (context) {
                      if (!isFullPage && context.isLargeScreen) {
                        context.pushReplacementNamed(
                          Routes.spaceSettingsNotifications.name,
                          pathParameters: {'spaceId': spaceId},
                        );
                      } else {
                        context.pushNamed(
                          Routes.spaceSettingsNotifications.name,
                          pathParameters: {'spaceId': spaceId},
                        );
                      }
                    },
                  ),
                  if (ref.watch(isCalendarSyncActiveProvider).valueOrNull ??
                      true)
                    SettingsTile.switchTile(
                      initialValue:
                          ref
                              .watch(shouldSyncRoomProvider(spaceId))
                              .valueOrNull ??
                          true,
                      leading: const Icon(Atlas.calendar_dots_thin),
                      onToggle: (newVal) {
                        setRoomSyncPreference(
                          ref,
                          L10n.of(context),
                          spaceId,
                          newVal,
                        );
                      },
                      title: Text(L10n.of(context).syncThisCalendarTitle),
                      description: Text(L10n.of(context).syncThisCalendarDesc),
                    ),
                ],
              ),
              SettingsSection(
                title: Text(lang.spaceConfiguration),
                tiles: <SettingsTile>[
                  SettingsTile(
                    title: Text(lang.accessAndVisibility),
                    description: Text(lang.spaceConfigurationDescription),
                    leading: const Icon(Atlas.lab_appliance_thin),
                    onPressed: (context) {
                      if (!isFullPage && context.isLargeScreen) {
                        context.pushReplacementNamed(
                          Routes.spaceSettingsVisibility.name,
                          pathParameters: {'spaceId': spaceId},
                        );
                      } else {
                        context.pushNamed(
                          Routes.spaceSettingsVisibility.name,
                          pathParameters: {'spaceId': spaceId},
                        );
                      }
                    },
                  ),
                  SettingsTile(
                    key: appsMenu,
                    title: Text(lang.apps),
                    description: Text(lang.customizeAppsAndTheirFeatures),
                    leading: const Icon(Atlas.info_circle_thin),
                    onPressed: (context) {
                      if (!isFullPage && context.isLargeScreen) {
                        context.pushReplacementNamed(
                          Routes.spaceSettingsApps.name,
                          pathParameters: {'spaceId': spaceId},
                        );
                      } else {
                        context.pushNamed(
                          Routes.spaceSettingsApps.name,
                          pathParameters: {'spaceId': spaceId},
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
