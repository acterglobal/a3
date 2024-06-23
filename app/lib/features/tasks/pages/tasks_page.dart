import 'package:acter/common/widgets/default_page_header.dart';
import 'package:acter/features/tasks/providers/tasklists.dart';
import 'package:acter/features/tasks/sheets/create_update_task_list.dart';
import 'package:acter/features/tasks/widgets/all_tasks_done.dart';
import 'package:acter/features/tasks/widgets/task_list_item_card.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class TasksPage extends ConsumerWidget {
  static const createNewTaskListKey = Key('tasks-create-list');
  static const taskListsKey = Key('tasks-task-lists');

  TasksPage({super.key});

  final ValueNotifier<bool> showCompletedTask = ValueNotifier(false);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskLists = ref.watch(tasksListsProvider);
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          PageHeaderWidget(
            title: L10n.of(context).tasks,
            actions: [
              ValueListenableBuilder(
                valueListenable: showCompletedTask,
                builder: (context, value, child) {
                  return TextButton.icon(
                    onPressed: () => showCompletedTask.value = !value,
                    icon: Icon(
                      value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                    ),
                    label: Text(
                      value
                          ? L10n.of(context).hideCompleted
                          : L10n.of(context).showCompleted,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  );
                },
              ),
              IconButton(
                key: createNewTaskListKey,
                icon: const Icon(Atlas.plus_circle),
                onPressed: () => showCreateUpdateTaskListBottomSheet(context),
              ),
            ],
            expandedContent: Text(
              L10n.of(context).todoListsAndTasksOfAllYourSpaces,
              softWrap: true,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          taskLists.when(
            data: (taskLists) {
              if (taskLists.isEmpty) {
                return const SliverToBoxAdapter(child: AllTasksDone());
              }
              return SliverList(
                key: taskListsKey,
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    TaskList taskList = taskLists[index];
                    return ValueListenableBuilder(
                      valueListenable: showCompletedTask,
                      builder: (context, value, child) {
                        return TaskListItemCard(
                          taskList: taskList,
                          showCompletedTask: value,
                          showSpace: true,
                        );
                      },
                    );
                  },
                  childCount: taskLists.length,
                ),
              );
            },
            error: (error, stack) => SliverToBoxAdapter(
              child: SizedBox(
                height: 450,
                child: Center(
                  child: Text(
                    L10n.of(context).loadingTasksFailed(error),
                  ),
                ),
              ),
            ),
            loading: () => SliverToBoxAdapter(
              child: SizedBox(
                height: 450,
                child: Center(
                  child: Text(L10n.of(context).loading),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
