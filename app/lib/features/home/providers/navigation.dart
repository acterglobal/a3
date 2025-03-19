import 'package:acter/common/tutorial_dialogs/bottom_navigation_tutorials/bottom_navigation_tutorials.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/home/data/models/nav_item.dart';
import 'package:acter/features/home/widgets/activities_icon.dart';
import 'package:acter/features/home/widgets/chats_icon.dart';
import 'package:acter/features/home/widgets/custom_selected_icon.dart';
import 'package:acter/features/news/widgets/news_full_view.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

const fallbackBottomBarIdx = 0;

final bottomBarItems = [
  BottomBarNavigationItem(
    icon: const Icon(Atlas.home_thin, key: MainNavKeys.dashboardHome),
    activeIcon: const CustomSelectedIcon(
      icon: Icon(Atlas.home_bold),
      key: MainNavKeys.dashboardHome,
    ),
    label: 'Dashboard',
    initialLocation: Routes.dashboard.route,
    tutorialGlobalKey: bottomDashboardKey,
  ),
  BottomBarNavigationItem(
    icon: const Icon(key: MainNavKeys.updates, Atlas.megaphone_thin),
    activeIcon: CustomSelectedIcon(
      icon: const Icon(Atlas.megaphone_thin),
      key: MainNavKeys.updates,
      onTap: () {
        NewsVerticalViewState.goToPage(0);
      },
    ),
    label: 'Updates',
    initialLocation: Routes.updates.route,
    tutorialGlobalKey: bottomUpdateKey,
  ),
  BottomBarNavigationItem(
    icon: const ChatsIcon(),
    activeIcon: const CustomSelectedIcon(icon: ChatsIcon()),
    label: 'Chat',
    initialLocation: Routes.chat.route,
    tutorialGlobalKey: bottomChatsKey,
  ),
  BottomBarNavigationItem(
    icon: const ActivitiesIcon(),
    activeIcon: const CustomSelectedIcon(icon: ActivitiesIcon()),
    label: 'Activities',
    initialLocation: Routes.activities.route,
    tutorialGlobalKey: bottomActivityKey,
  ),
  BottomBarNavigationItem(
    icon: const Icon(Atlas.magnifying_glass_thin, key: MainNavKeys.quickJump),
    activeIcon: const CustomSelectedIcon(
      key: MainNavKeys.quickJump,
      icon: Icon(Atlas.magnifying_glass_thin),
    ),
    label: 'Search',
    initialLocation: Routes.search.route,
    tutorialGlobalKey: bottomJumpToKey,
  ),
];
