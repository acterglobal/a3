import 'package:flutter/material.dart';

class BottomBarNavigationItem extends BottomNavigationBarItem {
  final String initialLocation;

  const BottomBarNavigationItem({
    required this.initialLocation,
    required Widget icon,
    String? label,
    Widget? activeIcon,
  }) : super(icon: icon, activeIcon: activeIcon, label: label);
}

class SidebarNavigationItem extends NavigationRailDestination {
  final String? location;
  final bool pushToNavigate;
  final bool isSpaceTab;
  const SidebarNavigationItem({
    this.location,
    this.pushToNavigate = false,
    this.isSpaceTab = false,
    required Widget icon,
    required Widget label,
  }) : super(icon: icon, label: label);
}
