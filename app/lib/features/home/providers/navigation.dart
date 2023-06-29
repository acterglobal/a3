import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/home/data/models/nav_item.dart';
import 'package:acter/features/home/widgets/custom_selected_icon.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/router/providers/router_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const fallbackSidebarIdx = 1;
const fallbackBottomBarIdx = 0;

final spaceItemsProvider = FutureProvider.autoDispose
    .family<List<SidebarNavigationItem>, BuildContext>((ref, context) async {
  final spaces = ref.watch(spacesProvider);

  return spaces.when(
    loading: () => [
      SidebarNavigationItem(
        icon: const Icon(Atlas.arrows_dots_rotate_thin),
        label: Text(
          'Loading Spaces',
          style: Theme.of(context).textTheme.labelSmall,
          softWrap: false,
        ),
        location: null,
      ),
    ],
    error: (error, stackTrace) => [
      SidebarNavigationItem(
        icon: const Icon(Atlas.warning_thin),
        label: Text(
          error.toString(),
          style: Theme.of(context).textTheme.labelSmall,
          softWrap: false,
        ),
        location: null,
      )
    ],
    data: (spaces) {
      spaces.sort((a, b) {
        // FIXME probably not the way we want to sort
        /// but at least this gives us a predictable order
        return a.getRoomId().toString().compareTo(b.getRoomId().toString());
      });

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
          error: (err, _trace) => SidebarNavigationItem(
            icon: const Icon(Atlas.warning_bold),
            label: Text(
              '$roomId: $err',
              style: Theme.of(context).textTheme.labelSmall,
              softWrap: false,
            ),
            location: '/$roomId',
          ),
          data: (info) => SidebarNavigationItem(
            icon: ActerAvatar(
              uniqueId: roomId,
              displayName: info.displayName,
              mode: DisplayMode.Space,
              avatar: info.getAvatarImage(),
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
    },
  );
});

// provider that returns a string value
final sidebarItemsProvider = Provider.autoDispose
    .family<List<SidebarNavigationItem>, BuildContext>((ref, context) {
  final config = ref.watch(spaceItemsProvider(context));

  final features = [
    SidebarNavigationItem(
      icon: const Icon(Atlas.magnifying_glass_thin),
      label: Text(
        'Search',
        style: Theme.of(context).textTheme.labelSmall,
        softWrap: false,
      ),
      location: Routes.quickJump.route,
      pushToNavigate: true,
    ),
    SidebarNavigationItem(
      icon: const Icon(Atlas.home_thin),
      label: Text(
        'Overview',
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
      icon: const Icon(Atlas.audio_wave_thin),
      label: Column(
        children: [
          Text(
            'Activities',
            style: Theme.of(context).textTheme.labelSmall,
            softWrap: false,
          ),
          const SizedBox(height: 10),
          const Divider(indent: 10, endIndent: 10)
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

final bottomBarNav = [
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
    icon: const Icon(Atlas.audio_wave_thin),
    activeIcon: const CustomSelectedIcon(
      icon: Icon(Atlas.audio_wave_thin),
    ),
    label: 'Activities',
    initialLocation: Routes.activities.route,
  ),
  BottomBarNavigationItem(
    icon: const Icon(
      Atlas.magnifying_glass_thin,
    ),
    activeIcon: const CustomSelectedIcon(
      icon: Icon(
        Atlas.magnifying_glass_thin,
      ),
    ),
    label: 'Search',
    initialLocation: Routes.search.route,
  )
];

final currentSelectedBottomBarIndexProvider =
    Provider.autoDispose.family<int, BuildContext>((ref, context) {
  final location = ref.watch(currentRoutingLocation);
  debugPrint('bottom location: $location');
  final index =
      bottomBarNav.indexWhere((t) => location.startsWith(t.initialLocation));
  debugPrint('bottom index: $index');

  return index < 0 ? fallbackBottomBarIdx : index;
});
