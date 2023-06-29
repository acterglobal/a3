import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/widgets/default_page_header.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/todo/widgets/task_list_card.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

import 'package:acter/features/tasks/providers/tasklists.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TasksPage extends ConsumerWidget {
  const TasksPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskLists = ref.watch(tasksListsProvider);
    // return TasksPageX(client: client);
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          PageHeaderWidget(
            title: 'Tasks',
            sectionColor: Theme.of(context).colorScheme.tasksBG,
            actions: [
              IconButton(
                icon: const Icon(Atlas.funnel_sort_thin),
                onPressed: () {
                  customMsgSnackbar(
                    context,
                    'Task filters not yet implemented',
                  );
                },
              ),
              IconButton(
                icon: const Icon(Atlas.plus_circle),
                onPressed: () {
                  customMsgSnackbar(
                    context,
                    'TaskList Creation page not yet implemented',
                  );
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
                return SliverToBoxAdapter(
                  child: SizedBox(
                    height: 450,
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            'Congrats!',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Icon(
                              Atlas.check_circle_thin,
                              size: 50.0,
                              color: Theme.of(context).colorScheme.success,
                            ),
                          ),
                          Text(
                            'you are done with all your tasks!',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'see open tasks',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
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
          )
        ],
      ),
    );
  }
}
