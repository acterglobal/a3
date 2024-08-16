import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/config/app_shell.dart';
import 'package:acter/features/search/model/keys.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter/features/spaces/model/keys.dart';
import 'package:acter/features/tasks/sheets/create_update_task_list.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::search::quick_actions_builder');

class QuickActionsBuilder extends ConsumerWidget {
  final bool popBeforeRoute;

  const QuickActionsBuilder({
    super.key,
    required this.popBeforeRoute,
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
    final canPostPin = canPostPinProvider.valueOrNull ?? false;

    final canPostEventProvider = ref.watch(
      hasSpaceWithPermissionProvider('CanPostEvent'),
    );
    final canCreateTaskListProvider = ref.watch(
      hasSpaceWithPermissionProvider('CanPostTaskList'),
    );
    final canPostEvent = (canPostEventProvider.valueOrNull ?? false);
    final canPostTaskList = canCreateTaskListProvider.valueOrNull ?? false;
    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      spacing: 8,
      runSpacing: 10,
      children: List.from(
        [
          if (canPostNews)
            OutlinedButton.icon(
              key: QuickJumpKeys.createUpdateAction,
              onPressed: () => routeTo(context, Routes.actionAddUpdate),
              icon: const Icon(
                Atlas.plus_circle_thin,
                size: 18,
              ),
              label: Text(
                L10n.of(context).update,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          if (canPostPin)
            OutlinedButton.icon(
              key: QuickJumpKeys.createPinAction,
              onPressed: () => routeTo(context, Routes.actionAddPin),
              icon: const Icon(
                Atlas.plus_circle_thin,
                size: 18,
              ),
              label: Text(
                L10n.of(context).pin,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          if (canPostEvent)
            OutlinedButton.icon(
              key: QuickJumpKeys.createEventAction,
              onPressed: () => routeTo(context, Routes.createEvent),
              icon: const Icon(Atlas.plus_circle_thin, size: 18),
              label: Text(
                L10n.of(context).event,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          if (canPostTaskList)
            OutlinedButton.icon(
              key: QuickJumpKeys.createTaskListAction,
              onPressed: () => showCreateUpdateTaskListBottomSheet(context),
              icon: const Icon(Atlas.plus_circle_thin, size: 18),
              label: Text(
                L10n.of(context).taskList,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          if (isActive(LabsFeature.polls))
            OutlinedButton.icon(
              onPressed: () {
                _log.info('poll pressed');
              },
              icon: const Icon(Atlas.plus_circle_thin, size: 18),
              label: Text(
                L10n.of(context).poll,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          if (isActive(LabsFeature.discussions))
            OutlinedButton.icon(
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
            ),
          OutlinedButton.icon(
            icon: const Icon(Atlas.connection),
            key: SpacesKeys.actionCreate,
            onPressed: () => routeTo(context, Routes.createSpace),
            label: Text(L10n.of(context).createSpace),
          ),
          OutlinedButton.icon(
            key: QuickJumpKeys.bugReport,
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.textHighlight,
              side: BorderSide(
                width: 1,
                color: Theme.of(context).colorScheme.textHighlight,
              ),
            ),
            icon: const Icon(Atlas.bug_clipboard_thin, size: 18),
            label: Text(
              L10n.of(context).reportBug,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            onPressed: () async {
              if (popBeforeRoute) {
                Navigator.pop(context);
              }
              await openBugReport(context);
            },
          ),
        ],
      ),
    );
  }

  void routeTo(BuildContext context, Routes route) {
    if (popBeforeRoute) {
      Navigator.pop(context);
    }
    context.pushNamed(route.name);
  }
}
