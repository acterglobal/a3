import 'package:flutter/material.dart';

class BottomBarNavigationItem extends BottomNavigationBarItem {
  final String initialLocation;

  const BottomBarNavigationItem({
    required this.initialLocation,
    required super.icon,
    super.label,
    super.activeIcon,
  });
}

class SidebarNavigationItem extends NavigationRailDestination {
  final String? location;
  final bool pushToNavigate;
  final bool isSpaceTab;
  const SidebarNavigationItem({
    this.location,
    this.pushToNavigate = false,
    this.isSpaceTab = false,
    required super.icon,
    required super.label,
  });
}
