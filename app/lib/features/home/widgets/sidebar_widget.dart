import 'package:acter/features/home/controllers/home_controller.dart';
import 'package:acter/features/home/widgets/user_avatar.dart';
import 'package:acter/common/dialogs/logout_confirmation.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'dart:typed_data';

class SidebarNavigationItem extends NavigationRailDestination {
  final String? location;
  const SidebarNavigationItem({
    this.location,
    required Widget icon,
    required Widget label,
  }) : super(icon: icon, label: label);
}

class ProfileData {
  final String displayName;
  final Uint8List? avatar;
  const ProfileData(this.displayName, this.avatar);
}

final groupProfileDataProvider =
    FutureProvider.family<ProfileData, Group>((ref, group) async {
  // FIXME: how to get informed about updates!?!
  final profile = await group.getProfile();
  final name = profile.getDisplayName();
  final displayName = name ?? group.getRoomId();
  if (!profile.hasAvatar()) {
    return ProfileData(displayName, null);
  }
  final avatar = await profile.getThumbnail(24, 24);
  return ProfileData(displayName, avatar.asTypedList());
});

final spacesProvider = FutureProvider<List<Group>>((ref) async {
  final client = ref.watch(homeStateProvider)!;
  // FIXME: how to get informed about updates!?!
  final groups = await client.groups();
  return groups.toList();
});

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
    data: (spaces) => spaces.map((space) {
      final profileData = ref.watch(groupProfileDataProvider(space));
      final roomId = space.getRoomId();
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
          icon: info.avatar != null
              ? CircleAvatar(
                  foregroundImage: ResizeImage(
                    MemoryImage(
                      info.avatar!,
                    ),
                    width: 24,
                    height: 24,
                  ),
                  radius: 24,
                )
              : SvgPicture.asset(
                  'assets/icon/acter.svg',
                  height: 24,
                  width: 24,
                ),
          label: Text(
            info.displayName,
            style: Theme.of(context).textTheme.labelSmall,
            softWrap: false,
          ),
          location: '/$roomId',
        ),
      );
    }).toList(),
  );
});

// provider that returns a string value
final sidebarItemsProvider =
    Provider.family<List<SidebarNavigationItem>, BuildContext>((ref, context) {
  AsyncValue<List<SidebarNavigationItem>> config =
      ref.watch(spaceItemsProvider(context));

  final features = [
    SidebarNavigationItem(
      icon: SvgPicture.asset(
        'assets/icon/acter.svg',
        height: 24,
        width: 24,
      ),
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
      label: Text(
        'Chat',
        style: Theme.of(context).textTheme.labelSmall,
        softWrap: false,
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
      return [
        ...features,
        const SidebarNavigationItem(
          icon: Divider(color: Colors.blueGrey),
          label: Text(''),
        ),
        ...spaces
      ];
    },
  );
});
final goRouterProvider = ChangeNotifierProvider.family<GoRouter, BuildContext>(
  (ref, context) => GoRouter.of(context),
);

final currentSelectedSidebarIndexProvider =
    Provider.family<int, BuildContext>((ref, context) {
  final items = ref.watch(sidebarItemsProvider(context));
  final location =
      ref.watch(goRouterProvider(context).select((g) => g.location));
  final index = items.indexWhere(
      (t) => t.location != null && location.startsWith(t.location!));
  // if index not found (-1), return 0
  return index < 0 ? 0 : index;
});

class SidebarWidget extends ConsumerWidget {
  final NavigationRailLabelType labelType;
  final void Function() handleBugReport;
  const SidebarWidget({
    super.key,
    required this.handleBugReport,
    required this.labelType,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sidebarNavItems = ref.watch(sidebarItemsProvider(context));
    final selectedSidebarIndex =
        ref.watch(currentSelectedSidebarIndexProvider(context));
    final isGuest = ref.watch(homeStateProvider)!.isGuest();

    return AdaptiveScaffold.standardNavigationRail(
      // main logic
      destinations: sidebarNavItems,
      selectedIndex: selectedSidebarIndex,
      onDestinationSelected: (tabIndex) {
        if (tabIndex != selectedSidebarIndex &&
            sidebarNavItems[tabIndex].location != null) {
          // go to the initial location of the selected tab (by index)
          context.go(sidebarNavItems[tabIndex].location!);
        }
      },

      // configuration

      labelType: labelType,

      backgroundColor: Theme.of(context).navigationRailTheme.backgroundColor!,
      selectedIconTheme: const IconThemeData(
        size: 18,
        color: Colors.white,
      ),
      unselectedIconTheme: const IconThemeData(
        size: 18,
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(0),
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Visibility(
            visible: !ref.watch(homeStateProvider)!.isGuest(),
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              child: const UserAvatarWidget(),
            ),
          ),
          const Divider(
            indent: 18,
            endIndent: 18,
          )
        ],
      ),
      trailing: Expanded(
        child: Column(
          children: [
            const Spacer(),
            const Divider(
              indent: 18,
              endIndent: 18,
            ),
            InkWell(
              onTap: () => handleBugReport(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    const Icon(
                      Atlas.bug_file_thin,
                      color: Colors.white,
                    ),
                    Text(
                      'Report',
                      style: Theme.of(context).textTheme.labelSmall,
                      softWrap: false,
                    )
                  ],
                ),
              ),
            ),
            const Divider(
              indent: 18,
              endIndent: 18,
            ),
            Visibility(
              visible: !isGuest,
              child: InkWell(
                onTap: () => confirmationDialog(context, ref),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Atlas.exit_thin,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 5,
                        ),
                        child: Text(
                          'Log Out',
                          style: Theme.of(context).textTheme.labelSmall,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Visibility(
              visible: isGuest,
              child: InkWell(
                onTap: () => context.pushNamed('login'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Atlas.entrance_thin,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 5,
                        ),
                        child: Text(
                          'Log In',
                          style: Theme.of(context).textTheme.labelSmall,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).build(context);
  }
}
