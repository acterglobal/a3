import 'package:acter/common/widgets/centered_page.dart';
import 'package:acter/common/widgets/icons/tasks_icon.dart';
import 'package:acter/features/tasks/providers/tasks.dart';
import 'package:acter/features/tasks/widgets/task_info.dart';
import 'package:flutter/material.dart';

import 'package:acter/features/tasks/providers/tasklists.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskPage extends ConsumerWidget {
  static const taskListTitleKey = Key('task-list-title');
  final String taskListId;
  final String taskId;
  const TaskPage({
    required this.taskListId,
    required this.taskId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskList = ref.watch(taskListProvider(taskListId));
    final task = ref.watch(taskProvider(TaskQuery(taskListId, taskId)));
    return Scaffold(
      appBar: AppBar(
        title: Wrap(
          children: [
            const TasksIcon(),
            taskList.when(
              data: (d) => Text(key: taskListTitleKey, d.name()),
              error: (e, s) => Text('failed to load: $e'),
              loading: () => const Text('loading'),
            ),
          ],
        ),
      ),
      body: CenteredPage(
        child: Column(
          children: [
            task.when(
              data: (task) => TaskInfo(task: task),
              error: (e, s) => Text('failed to load: $e'),
              loading: () => const Text('loading task'),
            ),
            // following: comments
          ],
        ),
      ),
    );
  }
}
