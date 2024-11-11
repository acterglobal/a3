import 'package:acter/common/actions/select_space.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/toolkit/errors/error_page.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter/features/tasks/sheets/create_update_task_list.dart';
import 'package:acter/features/tasks/widgets/skeleton/tasks_list_skeleton.dart';
import 'package:acter/features/tasks/widgets/task_list_item_card.dart';
import 'package:acter/features/tasks/widgets/task_lists_empty.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Allows the user to select a tasklist. If no space is
/// selected prior, it will ask to select a space first.
/// Returns the tasList if the user selected one or `null`
/// if they didn't.
Future<TaskList?> selectTaskList({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final lang = L10n.of(context);
  String? spaceId = ref.read(selectedSpaceIdProvider);
  spaceId ??= await selectSpace(
    context: context,
    ref: ref,
    canCheck: 'CanPostTask',
  );
  if (!context.mounted) return null;

  if (spaceId == null) {
    EasyLoading.showError(
      lang.pleaseSelectSpace,
      duration: const Duration(seconds: 2),
    );
    return null;
  }

  final taskListId = await selectTaskListId(context: context, spaceId: spaceId);
  if (!context.mounted) return null;
  if (taskListId == null) {
    return null;
  }

  return await ref.read(taskListProvider(taskListId).future);
}

// Given a specific spaceId, show a modal bottom sheet allowing
// the user to select any of the tasklists in it. Return the id
// of the selected task list or `null` if it was aborted.
Future<String?> selectTaskListId({
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
    final tasklistsLoader = ref.watch(taskListsProvider(spaceId));
    final canAdd = ref
            .watch(roomMembershipProvider(spaceId))
            .valueOrNull
            ?.canString('CanPostTaskList') ==
        true;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              Expanded(child: Text(lang.selectTaskList)),
              if (canAdd)
                ActerInlineTextButton.icon(
                  icon: Icon(PhosphorIcons.plus()),
                  onPressed: () {
                    showCreateUpdateTaskListBottomSheet(
                      context,
                      initialSelectedSpace: spaceId,
                    );
                  },
                  label: Text(lang.addTaskList),
                ),
            ],
          ),
        ),
        Expanded(
          child: tasklistsLoader.when(
            data: (tasklists) {
              if (tasklists.isEmpty) {
                return TaskListsEmptyState(
                  canAdd: canAdd,
                  inSearch: false,
                  spaceId: spaceId,
                );
              }

              return ListView.builder(
                itemCount: tasklists.length,
                shrinkWrap: true,
                itemBuilder: (context, idx) => TaskListItemCard(
                  onTitleTap: () => Navigator.of(context).pop(tasklists[idx]),
                  taskListId: tasklists[idx],
                  canExpand: false,
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
