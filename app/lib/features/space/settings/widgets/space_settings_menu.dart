import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/spaces/space_parent_badge.dart';
import 'package:acter/router/providers/router_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:go_router/go_router.dart';

const defaultSpaceSettingsMenuKey = Key('space-settings-menu');

class SpaceSettingsMenu extends ConsumerWidget {
  final String spaceId;
  const SpaceSettingsMenu({
    required this.spaceId,
    super.key = defaultSpaceSettingsMenuKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = ref.watch(currentRoutingLocation);
    final size = MediaQuery.of(context).size;
    bool isSelected(Routes route) {
      debugPrint(
        '${route.route} $currentRoute, ${currentRoute == route.route}',
      );
      return currentRoute == route.route;
    }

    final spaceProfile = ref.watch(spaceProfileDataForSpaceIdProvider(spaceId));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ...spaceProfile.when(
              data: (spaceProfile) => [
                SpaceParentBadge(
                  spaceId: spaceId,
                  badgeSize: 18,
                  child: ActerAvatar(
                    mode: DisplayMode.Space,
                    displayName: spaceProfile.profile.displayName,
                    tooltip: TooltipStyle.None,
                    uniqueId: spaceId,
                    avatar: spaceProfile.profile.getAvatarImage(),
                    size: 35,
                  ),
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
                  uniqueId: spaceId,
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ListTile(
                title: const Text('Access & Visibility'),
                subtitle: const Text(
                  'Configure, who can view and how to join this space',
                ),
                leading: const Icon(Atlas.lab_appliance_thin),
                selected: isSelected(Routes.settingsLabs),
                enabled: false,
                onTap: () {
                  isDesktop(context) || size.width > 770
                      ? context.goNamed(Routes.settingsLabs.name)
                      : context.pushNamed(Routes.settingsLabs.name);
                },
              ),
              ListTile(
                title: const Text('Apps'),
                subtitle: const Text('Customize Apps and their features'),
                leading: const Icon(Atlas.info_circle_thin),
                selected: isSelected(Routes.info),
                onTap: () {
                  isDesktop(context) || size.width > 770
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
        ),
      ),
    );
  }
}
