import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/features/tasks/models/tasks.dart';
import 'package:acter/features/tasks/providers/task_items_providers.dart';
import 'package:acter/features/tasks/actions/create_task.dart';
import 'package:acter/features/tasks/widgets/skeleton/task_items_skeleton.dart';
import 'package:acter/features/tasks/widgets/task_item.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::tasks::widgets::task_items_list');

class TaskItemsListWidget extends ConsumerStatefulWidget {
  final TaskList taskList;
  final bool showCompletedTask;

  const TaskItemsListWidget({
    super.key,
    required this.taskList,
    this.showCompletedTask = false,
  });

  static TaskItemsSkeleton loading() => const TaskItemsSkeleton();

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      TaskItemsListWidgetState();
}

class TaskItemsListWidgetState extends ConsumerState<TaskItemsListWidget> {
  final ValueNotifier<bool> showInlineAddTask = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    final overviewLoader = ref.watch(taskItemsListProvider(widget.taskList));
    return overviewLoader.when(
      data: (overview) => taskData(context, overview),
      error: (e, s) {
        _log.severe('Failed to load tasklist', e, s);
        return Text(L10n.of(context).errorLoadingTasks(e));
      },
      loading: () => const TaskItemsSkeleton(),
    );
  }

  Widget taskData(BuildContext context, TasksOverview overview) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        openTasksEntries(context, overview),
        inlineAddTask(),
        doneTasksEntries(context, overview),
      ],
    );
  }

  Widget openTasksEntries(BuildContext context, TasksOverview overview) {
    if (overview.openTasks.isEmpty) {
      return const SizedBox.shrink();
    }
    final taskListId = widget.taskList.eventIdStr();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final taskId in overview.openTasks)
          TaskItem(
            onTap: () => showInlineAddTask.value = false,
            taskListId: taskListId,
            taskId: taskId,
          ),
      ],
    );
  }

  Widget inlineAddTask() {
    final taskListId = widget.taskList.eventIdStr();
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: ActerInlineTextButton(
        key: Key('task-list-$taskListId-add-task-inline'),
        onPressed:
            () => showCreateTaskBottomSheet(context, taskList: widget.taskList),
        child: Text(L10n.of(context).addTask),
      ),
    );
  }

  Widget doneTasksEntries(BuildContext context, TasksOverview overview) {
    if (overview.doneTasks.isEmpty || !widget.showCompletedTask) {
      return const SizedBox.shrink();
    }
    final taskListId = widget.taskList.eventIdStr();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            const Expanded(child: Divider(indent: 20, endIndent: 20)),
            Text(
              L10n.of(context).countTasksCompleted(overview.doneTasks.length),
            ),
            const Expanded(child: Divider(indent: 20, endIndent: 20)),
          ],
        ),
        for (final taskId in overview.doneTasks)
          TaskItem(
            taskListId: taskListId,
            taskId: taskId,
            onTap: () => showInlineAddTask.value = false,
          ),
      ],
    );
  }
}
