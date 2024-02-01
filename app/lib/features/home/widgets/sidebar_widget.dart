import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/user_avatar.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/home/providers/navigation.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SidebarWidget extends ConsumerWidget {
  final NavigationRailLabelType labelType;
  final StatefulNavigationShell navigationShell;

  const SidebarWidget({
    super.key = Keys.mainNav,
    required this.labelType,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sidebarNavItems = ref.watch(sidebarItemsProvider(context));
    final isGuest = ref.watch(alwaysClientProvider).isGuest();

    return AdaptiveScaffold.standardNavigationRail(
      // main logic
      destinations: sidebarNavItems,
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (tabIndex) {
        if (sidebarNavItems[tabIndex].location != null) {
          final item = sidebarNavItems[tabIndex];
          // go to the initial location of the selected tab (by index)
          if (item.isSpaceTab) {
            context.go(item.location!);
          } else if (item.pushToNavigate) {
            context.push(item.location!);
          } else {
            navigationShell.goBranch(
              tabIndex,
              initialLocation: tabIndex == navigationShell.currentIndex,
            );
          }
        }
      },

      // configuration
      labelType: labelType,
      selectedIconTheme: const IconThemeData(size: 18, color: Colors.white),
      unselectedIconTheme: const IconThemeData(size: 18, color: Colors.white),
      padding: const EdgeInsets.all(0),
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Visibility(
            visible: !isGuest,
            child: Container(
              key: Keys.avatar,
              margin: const EdgeInsets.only(top: 8),
              child: InkWell(
                onTap: () => context.pushNamed(Routes.myProfile.name),
                child: const UserAvatarWidget(size: 20),
              ),
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
        ],
      ),
      trailing: Expanded(
        child: Column(
          children: [
            const Spacer(),
            const Divider(indent: 18, endIndent: 18),
            InkWell(
              onTap: () => context.pushNamed(Routes.bugReport.name),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    const Icon(Atlas.bug_file_thin, color: Colors.white),
                    Text(
                      'Report',
                      style: Theme.of(context).textTheme.labelSmall,
                      softWrap: false,
                    ),
                  ],
                ),
              ),
            ),
            Visibility(
              visible: isGuest,
              child: InkWell(
                key: Keys.loginBtn,
                onTap: () => context.pushNamed(Routes.authLogin.name),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Column(
                    children: [
                      const Icon(Atlas.entrance_thin),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Text(
                          AppLocalizations.of(context)!.logIn,
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
