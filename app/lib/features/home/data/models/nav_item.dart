import 'package:acter/router/utils.dart';
import 'package:flutter/material.dart';

class BottomBarNavigationItem extends BottomNavigationBarItem {
  final String initialLocation;
  final GlobalKey tutorialGlobalKey;

  const BottomBarNavigationItem({
    required this.initialLocation,
    required this.tutorialGlobalKey,
    required super.icon,
    super.label,
    super.activeIcon,
  });
}

class SidebarNavigationItem extends NavigationRailDestination {
  final String? location;
  final bool pushToNavigate;
  final bool isSpaceTab;
  final GlobalKey? tutorialGlobalKey;
  final ShellBranch? branch;

  const SidebarNavigationItem({
    this.location,
    this.pushToNavigate = false,
    this.isSpaceTab = false,
    this.tutorialGlobalKey,
    this.branch,
    required super.icon,
    required super.label,
  });
}
