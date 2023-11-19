import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/search/model/keys.dart';
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

    final canPostEventProvider = ref.watch(
      hasSpaceWithPermissionProvider('CanPostEvent'),
    );
    final canPostEvent = isActive(LabsFeature.events) &&
        (canPostEventProvider.valueOrNull ?? false);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 8,
      runSpacing: 10,
      children: List.from(
        [
          canPostNews
              ? OutlinedButton.icon(
                  key: QuickJumpKeys.createUpdateAction,
                  onPressed: () {
                    navigateTo(route: Routes.actionAddUpdate, push: true);
                  },
                  icon: const Icon(
                    Atlas.plus_circle_thin,
                    size: 18,
                  ),
                  label: Text(
                    'Update',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                )
              : null,
          canPostPin
              ? OutlinedButton.icon(
                  onPressed: () => context.pushNamed(Routes.actionAddPin.name),
                  icon: const Icon(
                    Atlas.plus_circle_thin,
                    size: 18,
                  ),
                  label: Text(
                    'Pin',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                )
              : null,
          canPostEvent
              ? OutlinedButton.icon(
                  onPressed: () => context.pushNamed(Routes.createEvent.name),
                  icon: const Icon(Atlas.plus_circle_thin, size: 18),
                  label: Text(
                    'Event',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                )
              : null,
          isActive(LabsFeature.polls)
              ? OutlinedButton.icon(
                  onPressed: () {
                    debugPrint('poll');
                  },
                  icon: const Icon(Atlas.plus_circle_thin, size: 18),
                  label: Text(
                    'Poll',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
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
                  icon: const Icon(
                    Atlas.plus_circle_thin,
                    size: 18,
                  ),
                  label: Text(
                    'Discussion',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                )
              : null,
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.greenAccent,
              side: const BorderSide(width: 1, color: Colors.greenAccent),
            ),
            icon: const Icon(Atlas.bug_clipboard_thin, size: 18),
            label: Text(
              'Report bug',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            onPressed: () => navigateTo(route: Routes.bugReport, push: true),
          ),
        ].where((element) => element != null),
      ),
    );
  }
}
