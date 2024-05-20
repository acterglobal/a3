import 'package:acter/common/models/types.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActivitiesIcon extends ConsumerWidget {
  const ActivitiesIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(hasActivitiesProvider);
    const baseIcon = Icon(
      Atlas.audio_wave_thin,
      key: MainNavKeys.activities,
    );
    switch (activities) {
      case UrgencyBadge.important:
        return Badge(
          backgroundColor: Theme.of(context).colorScheme.badgeImportant,
          child: baseIcon,
        );
      case UrgencyBadge.urgent:
        return Badge(
          backgroundColor: Theme.of(context).colorScheme.badgeUrgent,
          child: baseIcon,
        );
      case UrgencyBadge.unread:
        return Badge(
          backgroundColor: Theme.of(context).colorScheme.badgeUnread,
          child: baseIcon,
        );
      default:
        // read and none, we do not show any icon to prevent notification fatigue
        return baseIcon;
    }
  }
}
