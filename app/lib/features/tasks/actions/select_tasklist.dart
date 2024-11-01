import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/errors/error_page.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter/features/tasks/widgets/skeleton/tasks_list_skeleton.dart';
import 'package:acter/features/tasks/widgets/task_list_item_card.dart';
import 'package:acter/features/tasks/widgets/task_lists_empty.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const Key selectSpaceDrawerKey = Key('space-widgets-select-space-drawer');

Future<String?> selectTaskList({
  required BuildContext context,
  required String spaceId,
}) async {
  return await showModalBottomSheet(
    showDragHandle: true,
    enableDrag: true,
    context: context,
    isDismissible: true,
    builder: (context) => _SelectTaskList(spaceId: spaceId),
  );
}

class _SelectTaskList extends ConsumerWidget {
  final String spaceId;
  const _SelectTaskList({required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final tasklistsLoader = ref.watch(
      tasksListSearchProvider(
        (spaceId: spaceId, searchText: ''),
      ),
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [Expanded(child: Text(lang.selectTaskList))],
          ),
        ),
        Expanded(
          child: tasklistsLoader.when(
            data: (tasklists) {
              if (tasklists.isEmpty) {
                final canAdd = ref
                        .watch(roomMembershipProvider(spaceId))
                        .valueOrNull
                        ?.canString('CanPostTaskList') ==
                    true;
                return TaskListsEmptyState(
                  canAdd: canAdd,
                  inSearch: false,
                  spaceId: spaceId,
                );
              }

              return SingleChildScrollView(
                child: ListView.builder(
                  itemCount: tasklists.length,
                  shrinkWrap: true,
                  itemBuilder: (context, idx) => TaskListItemCard(
                    onTitleTap: () => Navigator.of(context).pop(tasklists[idx]),
                    taskListId: tasklists[idx],
                    canExpand: false,
                  ),
                ),
              );
            },
            error: (error, stack) {
              return ErrorPage(
                background: const TasksListSkeleton(),
                error: error,
                stack: stack,
                onRetryTap: () => ref.invalidate(allTasksListsProvider),
              );
            },
            loading: () => const TasksListSkeleton(),
          ),
        ),
      ],
    );
  }
}
