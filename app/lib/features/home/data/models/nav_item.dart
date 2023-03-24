import 'package:flutter/material.dart';

class BottombarNavigationItem extends BottomNavigationBarItem {
  final String initialLocation;

  const BottombarNavigationItem({
    required this.initialLocation,
    required Widget icon,
    String? label,
    Widget? activeIcon,
  }) : super(icon: icon, activeIcon: activeIcon, label: label);
}

class SidebarNavigationItem extends NavigationRailDestination {
  final String? location;
  const SidebarNavigationItem({
    this.location,
    required Widget icon,
    required Widget label,
  }) : super(icon: icon, label: label);
}
