import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter/features/main/models/keys.dart';
import 'package:acter/features/main/widgets/badged_icon.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActivitiesIcon extends ConsumerWidget {
  const ActivitiesIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urgency = ref.watch(hasActivitiesProvider);
    return BadgedIcon(
      urgency: urgency,
      child: const Icon(
        Atlas.audio_wave_thin,
        key: MainNavKeys.activities,
        size: 18,
      ),
    );
  }
}
