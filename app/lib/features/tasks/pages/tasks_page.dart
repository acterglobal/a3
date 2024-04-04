import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/default_page_header.dart';
import 'package:acter/features/tasks/providers/tasklists.dart';
import 'package:acter/features/tasks/widgets/all_tasks_done.dart';
import 'package:acter/features/tasks/widgets/task_list_card.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class TasksPage extends ConsumerWidget {
  static const createNewTaskListKey = Key('tasks-create-list');
  static const taskListsKey = Key('tasks-task-lists');

  const TasksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskLists = ref.watch(tasksListsProvider);
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          PageHeaderWidget(
            title: L10n.of(context).tasks,
            sectionDecoration: const BoxDecoration(
              gradient: primaryGradient,
            ),
            actions: [
              IconButton(
                key: createNewTaskListKey,
                icon: const Icon(Atlas.plus_circle),
                onPressed: () {
                  context.pushNamed(Routes.actionAddTaskList.name);
                },
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
                    return TaskListCard(taskList: taskList);
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
