import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/home/data/models/nav_item.dart';
import 'package:acter/features/home/widgets/custom_selected_icon.dart';
import 'package:acter/routing.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const fallbackSidebarIdx = 1;
const fallbackBottombarIdx = 0;

final spaceItemsProvider =
    FutureProvider.family<List<SidebarNavigationItem>, BuildContext>(
        (ref, context) async {
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
              size: 24,
            ),
            label: Text(
              info.displayName,
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
final sidebarItemsProvider =
    Provider.family<List<SidebarNavigationItem>, BuildContext>((ref, context) {
  AsyncValue<List<SidebarNavigationItem>> config =
      ref.watch(spaceItemsProvider(context));

  final features = [
    SidebarNavigationItem(
      icon: const Icon(Atlas.magnifying_glass_thin),
      label: Text(
        'Search',
        style: Theme.of(context).textTheme.labelSmall,
        softWrap: false,
      ),
      location: '/quickjump',
      pushToNavigate: true,
    ),
    SidebarNavigationItem(
      icon: const Icon(Atlas.home_thin),
      label: Text(
        'Overview',
        style: Theme.of(context).textTheme.labelSmall,
        softWrap: false,
      ),
      location: '/dashboard',
    ),
    SidebarNavigationItem(
      // icon: const Badge(child: Icon(Atlas.chats_thin)), // TODO: Badge example
      icon: const Icon(Atlas.chats_thin),
      label: Column(
        children: [
          Text(
            'Chat',
            style: Theme.of(context).textTheme.labelSmall,
            softWrap: false,
          ),
          const SizedBox(height: 10),
          const Divider(
            indent: 10,
            endIndent: 10,
          )
        ],
      ),
      location: '/chat',
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
  const BottombarNavigationItem(
    icon: Icon(Atlas.home_thin),
    activeIcon: CustomSelectedIcon(
      icon: Icon(Atlas.home_bold),
    ),
    label: 'Dashboard',
    initialLocation: '/dashboard',
  ),
  const BottombarNavigationItem(
    icon: Icon(Atlas.bullhorn_thin),
    activeIcon: CustomSelectedIcon(
      icon: Icon(Atlas.bullhorn_thin),
    ),
    label: 'Updates',
    initialLocation: '/updates',
  ),
  const BottombarNavigationItem(
    icon: Icon(Atlas.chats_thin),
    activeIcon: CustomSelectedIcon(
      icon: Icon(Atlas.chats_thin),
    ),
    label: 'Chat',
    initialLocation: '/chat',
  ),
  const BottombarNavigationItem(
    icon: Icon(Atlas.heart_rate_clipboard_thin),
    activeIcon: CustomSelectedIcon(
      icon: Icon(Atlas.heart_rate_clipboard_thin),
    ),
    label: 'Activities',
    initialLocation: '/activities',
  ),
  const BottombarNavigationItem(
    icon: Icon(
      Atlas.magnifying_glass_thin,
    ),
    activeIcon: CustomSelectedIcon(
      icon: Icon(
        Atlas.magnifying_glass_thin,
      ),
    ),
    label: 'Search',
    initialLocation: '/search',
  )
];

final currentSelectedBottombarIndexProvider =
    Provider.autoDispose.family<int, BuildContext>((ref, context) {
  final location = ref.watch(currentRoutingLocation);
  debugPrint('bottom location: $location');
  final index =
      bottomBarNav.indexWhere((t) => location.startsWith(t.initialLocation));
  debugPrint('bottom index: $index');

  return index < 0 ? fallbackBottombarIdx : index;
});
