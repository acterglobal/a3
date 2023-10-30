import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/spaces/space_parent_badge.dart';
import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/home/data/models/nav_item.dart';
import 'package:acter/features/home/widgets/custom_selected_icon.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/router/providers/router_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const fallbackSidebarIdx = 1;
const fallbackBottomBarIdx = 0;

final spaceItemsProvider = FutureProvider.autoDispose
    .family<List<SidebarNavigationItem>, BuildContext>((ref, context) async {
  final spaces = ref.watch(spacesProvider);

  return spaces.map((space) {
    final profileData = ref.watch(spaceProfileDataProvider(space));
    final roomId = space.getRoomId().toString();
    return profileData.when(
      loading: () => SidebarNavigationItem(
        icon: const Icon(Atlas.arrows_dots_rotate_thin),
        label: Text(
          roomId,
          style: Theme.of(context).textTheme.labelSmall,
          softWrap: false,
        ),
        location: '/$roomId',
      ),
      error: (err, trace) => SidebarNavigationItem(
        icon: const Icon(Atlas.warning_bold),
        label: Text(
          '$roomId: $err',
          style: Theme.of(context).textTheme.labelSmall,
          softWrap: false,
        ),
        location: '/$roomId',
      ),
      data: (info) => SidebarNavigationItem(
        icon: SpaceParentBadge(
          roomId: roomId,
          child: ActerAvatar(
            uniqueId: roomId,
            displayName: info.displayName,
            mode: DisplayMode.Space,
            avatar: info.getAvatarImage(),
            size: 48,
          ),
        ),
        label: Text(
          info.displayName ?? roomId,
          style: Theme.of(context).textTheme.labelSmall,
          softWrap: false,
        ),
        location: '/$roomId',
      ),
    );
  }).toList();
});

final activitiesIconProvider = Provider.family<Widget, BuildContext>(
  (ref, context) {
    final activites = ref.watch(hasActivitiesProvider);
    const baseIcon = Icon(Atlas.audio_wave_thin);
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
    ),
    SidebarNavigationItem(
      icon: const Icon(Atlas.home_thin),
      label: Text(
        'Home',
        style: Theme.of(context).textTheme.labelSmall,
        softWrap: false,
      ),
      location: Routes.dashboard.route,
    ),
    SidebarNavigationItem(
      // icon: const Badge(child: Icon(Atlas.chats_thin)), // TODO: Badge example
      icon: const Icon(Atlas.chats_thin),
      label: Text(
        'Chat',
        style: Theme.of(context).textTheme.labelSmall,
        softWrap: false,
      ),
      location: Routes.chat.route,
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
      location: Routes.activities.route,
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
  debugPrint('location: $location');
  final index = items.indexWhere(
    (t) => t.location != null && location.startsWith(t.location!),
  );
  debugPrint('index: $index');
  // if index not found (-1), return 0
  return index < 0 ? fallbackSidebarIdx : index;
});

final bottomBarNavProvider =
    Provider.family<List<BottomBarNavigationItem>, BuildContext>(
        (ref, context) {
  final activitiesIcon = ref.watch(activitiesIconProvider(context));

  return [
    BottomBarNavigationItem(
      icon: const Icon(Atlas.home_thin),
      activeIcon: const CustomSelectedIcon(
        icon: Icon(Atlas.home_bold),
      ),
      label: 'Dashboard',
      initialLocation: Routes.dashboard.route,
    ),
    BottomBarNavigationItem(
      icon: const Icon(Atlas.megaphone_thin),
      activeIcon: const CustomSelectedIcon(
        icon: Icon(Atlas.megaphone_thin),
      ),
      label: 'Updates',
      initialLocation: Routes.updates.route,
    ),
    BottomBarNavigationItem(
      icon: const Icon(Atlas.chats_thin),
      activeIcon: const CustomSelectedIcon(
        icon: Icon(Atlas.chats_thin),
      ),
      label: 'Chat',
      initialLocation: Routes.chat.route,
    ),
    BottomBarNavigationItem(
      icon: activitiesIcon,
      activeIcon: CustomSelectedIcon(
        icon: activitiesIcon,
      ),
      label: 'Activities',
      initialLocation: Routes.activities.route,
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
    ),
  ];
});

final currentSelectedBottomBarIndexProvider =
    Provider.autoDispose.family<int, BuildContext>((ref, context) {
  final location = ref.watch(currentRoutingLocation);
  final bottomBarNav = ref.watch(bottomBarNavProvider(context));

  debugPrint('bottom location: $location');
  final index =
      bottomBarNav.indexWhere((t) => location.startsWith(t.initialLocation));
  debugPrint('bottom index: $index');

  return index < 0 ? fallbackBottomBarIdx : index;
});
