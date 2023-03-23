import 'package:acter/features/home/controllers/home_controller.dart';
import 'package:acter/features/home/widgets/user_avatar.dart';
import 'package:acter/common/dialogs/logout_confirmation.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class SidebarNavigationItem extends NavigationRailDestination {
  final String initialLocation;
  const SidebarNavigationItem({
    required this.initialLocation,
    required Widget icon,
    required Widget label,
  }) : super(icon: icon, label: label);
}

// provider that returns a string value
final sidebarItemsProvider =
    Provider.family<List<SidebarNavigationItem>, BuildContext>((ref, context) {
  return [
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
      initialLocation: '/dashboard',
    ),
    SidebarNavigationItem(
      icon: const Icon(Atlas.chats_thin),
      label: Text(
        'Chat',
        style: Theme.of(context).textTheme.labelSmall,
        softWrap: false,
      ),
      initialLocation: '/chat',
    ),
  ];
});
final goRouterProvider = ChangeNotifierProvider.family<GoRouter, BuildContext>(
    (ref, context) => GoRouter.of(context));

final currentSelectedSidebarIndexProvider =
    Provider.family<int, BuildContext>((ref, context) {
  final items = ref.watch(sidebarItemsProvider(context));
  final location =
      ref.watch(goRouterProvider(context).select((g) => g.location));
  final index = items.indexWhere((t) => location.startsWith(t.initialLocation));
  // if index not found (-1), return 0
  return index < 0 ? 0 : index;
});

class SidebarWidget extends ConsumerStatefulWidget {
  final NavigationRailLabelType labelType;
  final void Function() handleBugReport;
  @override
  ConsumerState<SidebarWidget> createState() => _SidebarWidgetState();
  const SidebarWidget(
      {super.key, required this.handleBugReport, required this.labelType});
}

class _SidebarWidgetState extends ConsumerState<SidebarWidget> {
  @override
  Widget build(BuildContext context) {
    final sidebarNavItems = ref.watch(sidebarItemsProvider(context));
    final selectedSidebarIndex =
        ref.watch(currentSelectedSidebarIndexProvider(context));
    final isGuest = ref.watch(homeStateProvider)!.isGuest();

    return AdaptiveScaffold.standardNavigationRail(
      // main logic
      destinations: sidebarNavItems,
      selectedIndex: selectedSidebarIndex,
      onDestinationSelected: (tabIndex) {
        if (tabIndex != selectedSidebarIndex) {
          // go to the initial location of the selected tab (by index)
          context.go(sidebarNavItems[tabIndex].initialLocation);
        }
      },

      // configuration

      labelType: widget.labelType,

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
              onTap: () => widget.handleBugReport(),
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
