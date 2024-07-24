import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

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
    final spaceAvatarInfo = ref.watch(roomAvatarInfoProvider(spaceId));
    final parentBadges =
        ref.watch(parentAvatarInfosProvider(spaceId)).valueOrNull;

    final notificationStatus =
        ref.watch(roomNotificationStatusProvider(spaceId));
    final curNotifStatus = notificationStatus.valueOrNull;
    final replaceRoute = !isFullPage && isLargeScreen(context);

    final spaceName = spaceAvatarInfo.displayName ?? spaceId;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: isFullPage,
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
                  Text(L10n.of(context).settings),
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
                title: Text(L10n.of(context).personalSettings),
                tiles: [
                  SettingsTile(
                    key: appsMenu,
                    title: Text(L10n.of(context).notificationsOverwrites),
                    description: Text(
                      L10n.of(context).notificationsOverwritesDescription,
                    ),
                    leading: curNotifStatus == 'muted'
                        ? const Icon(Atlas.bell_dash_bold, size: 18)
                        : const Icon(Atlas.bell_thin, size: 18),
                    onPressed: (context) {
                      replaceRoute
                          ? context.pushReplacementNamed(
                              Routes.spaceSettingsNotifications.name,
                              pathParameters: {'spaceId': spaceId},
                            )
                          : context.pushNamed(
                              Routes.spaceSettingsNotifications.name,
                              pathParameters: {'spaceId': spaceId},
                            );
                    },
                  ),
                ],
              ),
              SettingsSection(
                title: Text(L10n.of(context).spaceConfiguration),
                tiles: <SettingsTile>[
                  SettingsTile(
                    title: Text(L10n.of(context).accessAndVisibility),
                    description: Text(
                      L10n.of(context).spaceConfigurationDescription,
                    ),
                    leading: const Icon(Atlas.lab_appliance_thin),
                    onPressed: (context) {
                      replaceRoute
                          ? context.pushReplacementNamed(
                              Routes.spaceSettingsVisibility.name,
                              pathParameters: {'spaceId': spaceId},
                            )
                          : context.pushNamed(
                              Routes.spaceSettingsVisibility.name,
                              pathParameters: {'spaceId': spaceId},
                            );
                    },
                  ),
                  SettingsTile(
                    key: appsMenu,
                    title: Text(L10n.of(context).apps),
                    description: Text(
                      L10n.of(context).customizeAppsAndTheirFeatures,
                    ),
                    leading: const Icon(Atlas.info_circle_thin),
                    onPressed: (context) {
                      replaceRoute
                          ? context.pushReplacementNamed(
                              Routes.spaceSettingsApps.name,
                              pathParameters: {'spaceId': spaceId},
                            )
                          : context.pushNamed(
                              Routes.spaceSettingsApps.name,
                              pathParameters: {'spaceId': spaceId},
                            );
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
