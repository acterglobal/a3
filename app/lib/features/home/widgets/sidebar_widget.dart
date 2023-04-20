import 'package:acter/features/home/states/client_state.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/features/home/data/models/nav_item.dart';
import 'package:acter/common/widgets/user_avatar.dart';
import 'package:acter/common/dialogs/logout_confirmation.dart';
import 'package:acter/routing.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

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
        return a.getRoomId().compareTo(b.getRoomId());
      });

      return spaces.map((space) {
        final profileData = ref.watch(spaceProfileDataProvider(space));
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
            icon: info.hasAvatar()
                ? CircleAvatar(
                    foregroundImage: info.getAvatarImage()!,
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
    Provider.family<int, BuildContext>((ref, context) {
  final items = ref.watch(sidebarItemsProvider(context));
  final location =
      ref.watch(goRouterProvider.select((value) => value.location));
  final index = items.indexWhere(
    (t) => t.location != null && location.startsWith(t.location!),
  );
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
    final isGuest = ref.watch(clientProvider)!.isGuest();

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
            visible: !ref.watch(clientProvider)!.isGuest(),
            child: Container(
              key: Keys.avatar,
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
                key: Keys.logoutBtn,
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
                key: Keys.loginBtn,
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
