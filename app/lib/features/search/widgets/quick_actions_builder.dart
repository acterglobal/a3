import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/home/pages/home_shell.dart';
import 'package:acter/features/search/model/keys.dart';
import 'package:acter/features/search/model/util.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

final _log = Logger('a3::search::quick_actions_builder');

class QuickActionsBuilder extends ConsumerWidget {
  final NavigateTo navigateTo;

  const QuickActionsBuilder({
    super.key,
    required this.navigateTo,
  });

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
    final canCreateTaskListProvider = ref.watch(
      hasSpaceWithPermissionProvider('CanPostTaskList'),
    );
    final canPostEvent = (canPostEventProvider.valueOrNull ?? false);
    final canPostTaskList = isActive(LabsFeature.tasks) &&
        (canCreateTaskListProvider.valueOrNull ?? false);
    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      spacing: 8,
      runSpacing: 10,
      children: List.from(
        [
          canPostNews
              ? OutlinedButton.icon(
                  key: QuickJumpKeys.createUpdateAction,
                  onPressed: () =>
                      navigateTo(Routes.actionAddUpdate, push: true),
                  icon: const Icon(
                    Atlas.plus_circle_thin,
                    size: 18,
                  ),
                  label: Text(
                    L10n.of(context).update,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                )
              : null,
          canPostPin
              ? OutlinedButton.icon(
                  key: QuickJumpKeys.createPinAction,
                  onPressed: () => navigateTo(Routes.actionAddPin, push: true),
                  icon: const Icon(
                    Atlas.plus_circle_thin,
                    size: 18,
                  ),
                  label: Text(
                    L10n.of(context).pin,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                )
              : null,
          canPostEvent
              ? OutlinedButton.icon(
                  key: QuickJumpKeys.createEventAction,
                  onPressed: () => navigateTo(Routes.createEvent, push: true),
                  icon: const Icon(Atlas.plus_circle_thin, size: 18),
                  label: Text(
                    L10n.of(context).event,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                )
              : null,
          canPostTaskList
              ? OutlinedButton.icon(
                  key: QuickJumpKeys.createTaskListAction,
                  onPressed: () =>
                      navigateTo(Routes.actionAddTaskList, push: true),
                  icon: const Icon(Atlas.plus_circle_thin, size: 18),
                  label: Text(
                    L10n.of(context).taskList,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                )
              : null,
          isActive(LabsFeature.polls)
              ? OutlinedButton.icon(
                  onPressed: () {
                    _log.info('poll pressed');
                  },
                  icon: const Icon(Atlas.plus_circle_thin, size: 18),
                  label: Text(
                    L10n.of(context).poll,
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
                    _log.info('Discussion pressed');
                  },
                  icon: const Icon(
                    Atlas.plus_circle_thin,
                    size: 18,
                  ),
                  label: Text(
                    L10n.of(context).discussion,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                )
              : null,
          OutlinedButton.icon(
            key: QuickJumpKeys.bugReport,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.greenAccent,
              side: const BorderSide(width: 1, color: Colors.greenAccent),
            ),
            icon: const Icon(Atlas.bug_clipboard_thin, size: 18),
            label: Text(
              L10n.of(context).reportBug,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            onPressed: () => navigateTo(
              Routes.bugReport,
              prepare: (context) async {
                if (context.canPop()) {
                  context.pop();
                }
                await openBugReport(context);
                return true; // indicate this should stop processing.
              },
            ),
          ),
        ].where((element) => element != null),
      ),
    );
  }
}
