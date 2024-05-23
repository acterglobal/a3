import 'package:acter/common/models/types.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:flutter/material.dart';

class BadgedIcon extends StatelessWidget {
  final UrgencyBadge urgency;
  final Widget child;
  const BadgedIcon({required this.urgency, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    switch (urgency) {
      case UrgencyBadge.important:
        return Badge(
          backgroundColor: Theme.of(context).colorScheme.badgeImportant,
          child: child,
        );
      case UrgencyBadge.urgent:
        return Badge(
          backgroundColor: Theme.of(context).colorScheme.badgeUrgent,
          child: child,
        );
      case UrgencyBadge.unread:
        return Badge(
          backgroundColor: Theme.of(context).colorScheme.badgeUnread,
          child: child,
        );
      default:
        // read and none, we do not show any icon to prevent notification fatigue
        return child;
    }
  }
}
