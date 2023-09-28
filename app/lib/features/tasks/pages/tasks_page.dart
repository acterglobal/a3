import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/default_page_header.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/tasks/widgets/all_tasks_done.dart';
import 'package:acter/features/tasks/widgets/task_list_card.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

import 'package:acter/features/tasks/providers/tasklists.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TasksPage extends ConsumerWidget {
  const TasksPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskLists = ref.watch(tasksListsProvider);
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          PageHeaderWidget(
            title: 'Tasks',
            sectionDecoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            actions: [
              IconButton(
                icon: const Icon(Atlas.plus_circle),
                onPressed: () {
                  context.pushNamed(Routes.actionAddTaskList.name);
                },
              ),
            ],
            expandedContent: const Text(
              'ToDo Lists and Tasks of all your spaces can be found here',
            ),
          ),
          taskLists.when(
            data: (taskLists) {
              if (taskLists.isEmpty) {
                return const SliverToBoxAdapter(child: AllTasksDone());
              }
              return SliverList(
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
                  child: Text('Loading tasks failed: $error'),
                ),
              ),
            ),
            loading: () => const SliverToBoxAdapter(
              child: SizedBox(
                height: 450,
                child: Center(
                  child: Text('Loading'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
