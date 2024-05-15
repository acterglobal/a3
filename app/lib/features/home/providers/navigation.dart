import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/tutorial_dialogs/bottom_navigation_tutorials/bottom_navigation_tutorials.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/home/data/models/nav_item.dart';
import 'package:acter/features/home/widgets/custom_selected_icon.dart';
import 'package:acter/router/providers/router_providers.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::home::navigation');

const fallbackSidebarIdx = 1;
const fallbackBottomBarIdx = 0;

final spaceItemsProvider = FutureProvider.autoDispose
    .family<List<SidebarNavigationItem>, BuildContext>((ref, context) async {
  final spaces = ref.watch(spacesProvider);

  return spaces.map((space) {
    final profileData = ref.watch(spaceProfileDataProvider(space));
    final roomId = space.getRoomIdStr();
    final canonicalParent = ref.watch(canonicalParentProvider(roomId));
    return profileData.when(
      loading: () => SidebarNavigationItem(
        icon: const Icon(Atlas.arrows_dots_rotate_thin),
        label: Text(
          roomId,
          style: Theme.of(context).textTheme.labelSmall,
          softWrap: false,
        ),
        location: '/$roomId',
        isSpaceTab: true,
      ),
      error: (err, trace) => SidebarNavigationItem(
        icon: const Icon(Atlas.warning_bold),
        label: Text(
          '$roomId: $err',
          style: Theme.of(context).textTheme.labelSmall,
          softWrap: false,
        ),
        location: '/$roomId',
        isSpaceTab: true,
      ),
      data: (info) => SidebarNavigationItem(
        icon: ActerAvatar(
          mode: DisplayMode.Space,
          avatarInfo: AvatarInfo(
            uniqueId: roomId,
            displayName: info.displayName,
            avatar: info.getAvatarImage(),
          ),
          avatarsInfo: canonicalParent.valueOrNull != null
              ? [
                  AvatarInfo(
                    uniqueId: canonicalParent.valueOrNull!.space.getRoomIdStr(),
                    displayName:
                        canonicalParent.valueOrNull!.profile.displayName,
                    avatar:
                        canonicalParent.valueOrNull!.profile.getAvatarImage(),
                  ),
                ]
              : [],
          size: 48,
        ),
        label: Text(
          info.displayName ?? roomId,
          style: Theme.of(context).textTheme.labelSmall,
          softWrap: false,
        ),
        location: '/$roomId',
        isSpaceTab: true,
      ),
    );
  }).toList();
});

final activitiesIconProvider = Provider.family<Widget, BuildContext>(
  (ref, context) {
    final activites = ref.watch(hasActivitiesProvider);
    const baseIcon = Icon(
      Atlas.audio_wave_thin,
      key: MainNavKeys.activities,
    );
    switch (activites) {
      case HasActivities.important:
        return Badge(
          backgroundColor: Theme.of(context).colorScheme.badgeImportant,
          child: baseIcon,
        );
      case HasActivities.urgent:
        return Badge(
          backgroundColor: Theme.of(context).colorScheme.badgeUrgent,
          child: baseIcon,
        );
      case HasActivities.unread:
        return Badge(
          backgroundColor: Theme.of(context).colorScheme.badgeUnread,
          child: baseIcon,
        );
      default:
        // read and none, we do not show any icon to prevent notification fatigue
        return baseIcon;
    }
  },
);

// provider that returns a string value
final sidebarItemsProvider = Provider.autoDispose
    .family<List<SidebarNavigationItem>, BuildContext>((ref, context) {
  final config = ref.watch(spaceItemsProvider(context));
  final activitiesIcon = ref.watch(activitiesIconProvider(context));
  final features = [
    SidebarNavigationItem(
      icon: const Icon(
        Atlas.magnifying_glass_thin,
        key: MainNavKeys.quickJump,
      ),
      label: Text(
        'Jump',
        style: Theme.of(context).textTheme.labelSmall,
        softWrap: false,
      ),
      location: Routes.quickJump.route,
      pushToNavigate: true,
      tutorialGlobalKey: jumpToKey,
    ),
    SidebarNavigationItem(
      icon: const Icon(
        Atlas.home_thin,
        key: MainNavKeys.dashboardHome,
      ),
      label: Text(
        'Home',
        style: Theme.of(context).textTheme.labelSmall,
        softWrap: false,
      ),
      branch: ShellBranch.homeShell,
      tutorialGlobalKey: dashboardKey,
    ),
    SidebarNavigationItem(
      // icon: const Badge(child: Icon(Atlas.chats_thin)), // TODO: Badge example
      icon: const Icon(
        Atlas.chats_thin,
        key: MainNavKeys.chats,
      ),
      label: Text(
        'Chat',
        style: Theme.of(context).textTheme.labelSmall,
        softWrap: false,
      ),
      branch: ShellBranch.chatsShell,
      tutorialGlobalKey: chatsKey,
    ),
    SidebarNavigationItem(
      icon: activitiesIcon,
      label: Column(
        children: [
          Text(
            'Activities',
            style: Theme.of(context).textTheme.labelSmall,
            softWrap: false,
          ),
          const SizedBox(height: 10),
          const Divider(indent: 10, endIndent: 10),
        ],
      ),
      branch: ShellBranch.activitiesShell,
      tutorialGlobalKey: activityKey,
    ),
  ];

  return config.when(
    loading: () => features,
    error: (err, stack) => features,
    data: (spaces) {
      if (spaces.isEmpty) {
        return features;
      }
      return [...features, ...spaces];
    },
  );
});

final currentSelectedSidebarIndexProvider =
    Provider.autoDispose.family<int, BuildContext>((ref, context) {
  final items = ref.watch(sidebarItemsProvider(context));
  final location = ref.watch(currentRoutingLocation);
  _log.info('location: $location');
  final index = items.indexWhere(
    (t) => t.location != null && location.startsWith(t.location!),
  );
  _log.info('index: $index');
  // if index not found (-1), return 0
  return index < 0 ? fallbackSidebarIdx : index;
});

final bottomBarNavProvider =
    Provider.family<List<BottomBarNavigationItem>, BuildContext>(
        (ref, context) {
  final activitiesIcon = ref.watch(activitiesIconProvider(context));

  return [
    BottomBarNavigationItem(
      icon: const Icon(
        Atlas.home_thin,
        key: MainNavKeys.dashboardHome,
      ),
      activeIcon: const CustomSelectedIcon(
        icon: Icon(Atlas.home_bold),
        key: MainNavKeys.dashboardHome,
      ),
      label: 'Dashboard',
      initialLocation: Routes.dashboard.route,
      tutorialGlobalKey: dashboardKey,
    ),
    BottomBarNavigationItem(
      icon: const Icon(
        key: MainNavKeys.updates,
        Atlas.megaphone_thin,
      ),
      activeIcon: const CustomSelectedIcon(
        icon: Icon(Atlas.megaphone_thin),
        key: MainNavKeys.updates,
      ),
      label: 'Updates',
      initialLocation: Routes.updates.route,
      tutorialGlobalKey: updateKey,
    ),
    BottomBarNavigationItem(
      icon: const Icon(
        Atlas.chats_thin,
        key: MainNavKeys.chats,
      ),
      activeIcon: const CustomSelectedIcon(
        icon: Icon(Atlas.chats_thin),
        key: MainNavKeys.chats,
      ),
      label: 'Chat',
      initialLocation: Routes.chat.route,
      tutorialGlobalKey: chatsKey,
    ),
    BottomBarNavigationItem(
      icon: activitiesIcon,
      activeIcon: CustomSelectedIcon(
        icon: activitiesIcon,
      ),
      label: 'Activities',
      initialLocation: Routes.activities.route,
      tutorialGlobalKey: activityKey,
    ),
    BottomBarNavigationItem(
      icon: const Icon(
        Atlas.magnifying_glass_thin,
        key: MainNavKeys.quickJump,
      ),
      activeIcon: const CustomSelectedIcon(
        key: MainNavKeys.quickJump,
        icon: Icon(
          Atlas.magnifying_glass_thin,
        ),
      ),
      label: 'Search',
      initialLocation: Routes.search.route,
      tutorialGlobalKey: jumpToKey,
    ),
  ];
});

final currentSelectedBottomBarIndexProvider =
    Provider.autoDispose.family<int, BuildContext>((ref, context) {
  final location = ref.watch(currentRoutingLocation);
  final bottomBarNav = ref.watch(bottomBarNavProvider(context));

  _log.info('bottom location: $location');
  final index =
      bottomBarNav.indexWhere((t) => location.startsWith(t.initialLocation));
  _log.info('bottom index: $index');

  return index < 0 ? fallbackBottomBarIdx : index;
});
