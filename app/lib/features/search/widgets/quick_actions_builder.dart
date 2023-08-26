import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class QuickActionsBuilder extends ConsumerWidget {
  final Future<void> Function({
    Routes? route,
    bool push,
    String? target,
  }) navigateTo;

  const QuickActionsBuilder({
    Key? key,
    required this.navigateTo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = ref.watch(featuresProvider);
    bool isActive(f) => features.isActive(f);
    final canPostNewsProvider = ref.watch(
      hasSpaceWithPermissionProvider('CanPostNews'),
    );
    final canPostNews = canPostNewsProvider.valueOrNull ?? false;
    final canPostPinProvider = ref.watch(
      hasSpaceWithPermissionProvider('CanPostPin'),
    );
    final canPostPin =
        isActive(LabsFeature.pins) && (canPostPinProvider.valueOrNull ?? false);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 8,
      runSpacing: 10,
      children: List.from(
        [
          canPostNews
              ? OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amber,
                    side: const BorderSide(width: 2, color: Colors.amber),
                  ),
                  onPressed: () {
                    navigateTo(route: Routes.actionAddUpdate, push: true);
                    debugPrint('Update');
                  },
                  icon: const Icon(Atlas.plus_circle_thin),
                  label: const Text('Update'),
                )
              : null,
          isActive(LabsFeature.tasks)
              ? OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amber,
                    side: const BorderSide(width: 2, color: Colors.amber),
                  ),
                  onPressed: () {
                    navigateTo(route: Routes.actionAddTask, push: true);
                    debugPrint('Add Task');
                  },
                  icon: const Icon(Atlas.plus_circle_thin),
                  label: const Text('Task'),
                )
              : null,
          canPostPin
              ? OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purple,
                    side: const BorderSide(width: 2, color: Colors.purple),
                  ),
                  onPressed: () => context.pushNamed(Routes.actionAddPin.name),
                  icon: const Icon(Atlas.plus_circle_thin),
                  label: const Text('Pin'),
                )
              : null,
          isActive(LabsFeature.events)
              ? OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purple,
                    side: const BorderSide(width: 2, color: Colors.purple),
                  ),
                  onPressed: () => context.pushNamed(Routes.createEvent.name),
                  icon: const Icon(Atlas.plus_circle_thin),
                  label: const Text('Event'),
                )
              : null,
          isActive(LabsFeature.polls)
              ? OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green.shade900,
                    side: BorderSide(width: 2, color: Colors.green.shade900),
                  ),
                  onPressed: () {
                    debugPrint('poll');
                  },
                  icon: const Icon(Atlas.plus_circle_thin),
                  label: const Text('Poll'),
                )
              : null,
          isActive(LabsFeature.discussions)
              ? OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(width: 2, color: Colors.white),
                  ),
                  onPressed: () {
                    debugPrint('Discussion');
                  },
                  icon: const Icon(Atlas.plus_circle_thin),
                  label: const Text('Discussion'),
                )
              : null,
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.greenAccent,
              side: const BorderSide(width: 2, color: Colors.greenAccent),
            ),
            icon: const Icon(Atlas.bug_clipboard_thin),
            label: const Text('Report bug'),
            onPressed: () => navigateTo(route: Routes.bugReport, push: true),
          ),
        ].where((element) => element != null),
      ),
    );
  }
}
