import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/tutorial_dialogs/bottom_navigation_tutorials/bottom_navigation_tutorials.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/user_avatar.dart';
import 'package:acter/features/bug_report/actions/open_bug_report.dart';
import 'package:acter/features/bug_report/providers/bug_report_providers.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/home/widgets/activities_icon.dart';
import 'package:acter/features/home/widgets/chats_icon.dart';
import 'package:acter/router/providers/router_providers.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:extension_nullable/extension_nullable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class _MyUserAvatar extends ConsumerWidget {
  const _MyUserAvatar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      key: Keys.avatar,
      margin: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: () => context.pushNamed(Routes.settings.name),
        child: const UserAvatarWidget(size: 20),
      ),
    );
  }
}

class _SidebarItemIndicator extends ConsumerStatefulWidget {
  final List<Routes> routes;
  final bool reversed;

  const _SidebarItemIndicator({
    required this.routes,
    this.reversed = false,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      __SidebarItemIndicatorState();
}

class __SidebarItemIndicatorState extends ConsumerState<_SidebarItemIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: widget.reversed ? 1 : 0,
      vsync: this, // the SingleTickerProviderStateMixin
      duration: const Duration(milliseconds: 400),
    );
    ref.listenManual(currentRoutingLocation, (previous, next) {
      bool matches = false;
      for (final route in widget.routes) {
        if (next.startsWith(route.route)) {
          matches = true;
          break;
        }
      }
      if (widget.reversed) {
        if (!matches) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
      } else {
        if (matches) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).navigationRailTheme;
    return NavigationIndicator(
      animation: _controller,
      color: theme.indicatorColor,
      shape: theme.indicatorShape,
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final Widget icon;
  final Widget label;
  final Widget? indicator;
  final void Function() onTap;
  final Key? tutorialGlobalKey;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.indicator,
    this.tutorialGlobalKey,
  });

  @override
  Widget build(BuildContext context) {
    Widget inner = InkWell(
      onTap: onTap,
      child: icon,
    );
    indicator.map((p0) {
      inner = Stack(
        children: [
          Center(child: p0),
          Center(child: inner),
        ],
      );
    });
    return Container(
      height: 40,
      width: 40,
      key: tutorialGlobalKey,
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      child: inner,
    );
  }
}

class SidebarWidget extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const SidebarWidget({
    super.key = Keys.mainNav,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;

    List<Widget> menu = [
      const _MyUserAvatar(),
      const Divider(indent: 18, endIndent: 18),
      ..._menuItems(context, ref),
    ];

    if (size.height < 600) {
      // we don’t have enough space to show more,
      // only show our main menu
      return SingleChildScrollView(
        child: SizedBox(
          width: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ...menu,
              if (isBugReportingEnabled) ..._bugReporter(context),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: 72,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _MyUserAvatar(),
          const Divider(indent: 18, endIndent: 18),
          ..._menuItems(context, ref),
          const Divider(indent: 18, endIndent: 18),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: _spacesList(context, ref),
              ),
            ),
          ),
          if (isBugReportingEnabled) ..._bugReporter(context),
        ],
      ),
    );
  }

  List<Widget> _bugReporter(BuildContext context) {
    return [
      const Divider(indent: 18, endIndent: 18),
      InkWell(
        onTap: () => openBugReport(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              const Icon(Atlas.bug_file_thin),
              Text(
                L10n.of(context).report,
                style: Theme.of(context).textTheme.labelSmall,
                softWrap: false,
              ),
            ],
          ),
        ),
      ),
    ];
  }

  void goToBranch(ShellBranch branch) {
    navigationShell.goBranch(
      branch.index,
      initialLocation: branch.index == navigationShell.currentIndex,
    );
  }

  List<_SidebarItem> _menuItems(BuildContext context, WidgetRef ref) {
    return [
      _SidebarItem(
        icon: const Icon(
          Atlas.magnifying_glass_thin,
          key: MainNavKeys.quickJump,
          size: 18,
        ),
        label: Text(
          'Jump',
          style: Theme.of(context).textTheme.labelSmall,
          softWrap: false,
        ),
        onTap: () => context.pushNamed(Routes.quickJump.name),
        tutorialGlobalKey: jumpToKey,
        indicator: const _SidebarItemIndicator(routes: [Routes.quickJump]),
      ),
      _SidebarItem(
        icon: const Icon(
          Atlas.home_thin,
          key: MainNavKeys.dashboardHome,
          size: 18,
        ),
        label: Text(
          'Home',
          style: Theme.of(context).textTheme.labelSmall,
          softWrap: false,
        ),
        onTap: () => goToBranch(ShellBranch.homeShell),
        tutorialGlobalKey: dashboardKey,
        indicator: const _SidebarItemIndicator(
          reversed: true,
          routes: [
            Routes.quickJump,
            Routes.chat,
            Routes.activities,
          ],
        ),
      ),
      _SidebarItem(
        icon: const ChatsIcon(),
        label: Text(
          'Chat',
          style: Theme.of(context).textTheme.labelSmall,
          softWrap: false,
        ),
        onTap: () => goToBranch(ShellBranch.chatsShell),
        indicator: const _SidebarItemIndicator(routes: [Routes.chat]),
        tutorialGlobalKey: chatsKey,
      ),
      _SidebarItem(
        icon: const ActivitiesIcon(),
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
        onTap: () => goToBranch(ShellBranch.activitiesShell),
        indicator: const _SidebarItemIndicator(routes: [Routes.activities]),
        tutorialGlobalKey: activityKey,
      ),
    ];
  }

  List<_SidebarItem> _spacesList(BuildContext context, WidgetRef ref) {
    final bookmarkedSpaces = ref.watch(bookmarkedSpacesProvider);
    final otherSpaces = ref.watch(unbookmarkedSpacesProvider);

    return [].followedBy(bookmarkedSpaces).followedBy(otherSpaces).map((space) {
      final roomId = space.getRoomIdStr();
      final avatarInfo = ref.watch(roomAvatarInfoProvider(roomId));
      final parentBadges =
          ref.watch(parentAvatarInfosProvider(roomId)).valueOrNull;

      return _SidebarItem(
        icon: ActerAvatar(
          options: AvatarOptions(
            AvatarInfo(
              uniqueId: roomId,
              displayName: avatarInfo.displayName,
              avatar: avatarInfo.avatar,
            ),
            parentBadges: parentBadges,
            size: 48,
          ),
        ),
        label: Text(
          avatarInfo.displayName ?? roomId,
          style: Theme.of(context).textTheme.labelSmall,
          softWrap: false,
        ),
        onTap: () => context
            .goNamed(Routes.space.name, pathParameters: {'spaceId': roomId}),
      );
    }).toList();
  }
}
