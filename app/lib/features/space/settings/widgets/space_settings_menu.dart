import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/room/widgets/notifications_settings_tile.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:settings_ui/settings_ui.dart';

const defaultSpaceSettingsMenuKey = Key('space-settings-menu');

class SpaceSettingsMenu extends ConsumerWidget {
  final String spaceId;
  const SpaceSettingsMenu({
    required this.spaceId,
    super.key = defaultSpaceSettingsMenuKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final spaceProfile = ref.watch(spaceProfileDataForSpaceIdProvider(spaceId));
    final canonicalParent = ref.watch(canonicalParentProvider(spaceId));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ...spaceProfile.when(
              data: (spaceProfile) => [
                ActerAvatar(
                  mode: DisplayMode.Space,
                  avatarInfo: AvatarInfo(
                    uniqueId: spaceId,
                    displayName: spaceProfile.profile.displayName,
                    avatar: spaceProfile.profile.getAvatarImage(),
                  ),
                  avatarsInfo: canonicalParent.valueOrNull != null
                      ? [
                          AvatarInfo(
                            uniqueId: canonicalParent.valueOrNull!.space
                                .getRoomIdStr(),
                            displayName: canonicalParent
                                .valueOrNull!.profile.displayName,
                            avatar: canonicalParent.valueOrNull!.profile
                                .getAvatarImage(),
                          ),
                        ]
                      : [],
                  badgeSize: 18,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: Text(spaceProfile.profile.displayName ?? spaceId),
                ),
              ],
              error: (e, s) => [Text('Loading space failed: $e')],
              loading: () => [
                ActerAvatar(
                  mode: DisplayMode.Space,
                  tooltip: TooltipStyle.None,
                  avatarInfo: AvatarInfo(uniqueId: spaceId),
                  size: 35,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: Text(spaceId),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 15),
              child: Text('Settings'),
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SettingsList(
            sections: [
              SettingsSection(
                title: const Text('My Settings'),
                tiles: [
                  NotificationsSettingsTile(roomId: spaceId),
                ],
              ),
              SettingsSection(
                title: const Text('My Settings'),
                tiles: <SettingsTile>[
                  SettingsTile(
                    title: const Text('Access & Visibility'),
                    description: const Text(
                      'Configure, who can view and how to join this space',
                    ),
                    leading: const Icon(Atlas.lab_appliance_thin),
                    enabled: false,
                    onPressed: (context) {
                      isDesktop || size.width > 770
                          ? context.goNamed(Routes.settingsLabs.name)
                          : context.pushNamed(Routes.settingsLabs.name);
                    },
                  ),
                  SettingsTile(
                    title: const Text('Apps'),
                    description:
                        const Text('Customize Apps and their features'),
                    leading: const Icon(Atlas.info_circle_thin),
                    onPressed: (context) {
                      isDesktop || size.width > 770
                          ? context.goNamed(
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
