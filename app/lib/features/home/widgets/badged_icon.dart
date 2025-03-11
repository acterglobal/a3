import 'package:acter/common/models/types.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:flutter/material.dart';

class BadgedIcon extends StatelessWidget {
  final UrgencyBadge urgency;
  final Widget child;

  const BadgedIcon({required this.urgency, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (urgency) {
      UrgencyBadge.important => Badge(
        backgroundColor: colorScheme.badgeImportant,
        child: child,
      ),
      UrgencyBadge.urgent => Badge(
        backgroundColor: colorScheme.badgeUrgent,
        child: child,
      ),
      UrgencyBadge.unread => Badge(
        backgroundColor: colorScheme.badgeUnread,
        child: child,
      ),
      // read and none, we do not show any icon to prevent notification fatigue
      _ => child,
    };
  }
}
