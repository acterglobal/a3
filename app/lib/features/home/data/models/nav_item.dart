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
  const SidebarNavigationItem({
    this.location,
    this.pushToNavigate = false,
    required Widget icon,
    required Widget label,
  }) : super(icon: icon, label: label);
}
