import 'package:acter/common/widgets/centered_page.dart';
import 'package:acter/common/widgets/icons/tasks_icon.dart';
import 'package:acter/features/tasks/providers/tasklists.dart';
import 'package:acter/features/tasks/providers/tasks.dart';
import 'package:acter/features/tasks/widgets/task_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
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
    final task =
        ref.watch(taskProvider((taskListId: taskListId, taskId: taskId)));
    return Scaffold(
      appBar: AppBar(
        title: Wrap(
          children: [
            const TasksIcon(),
            taskList.when(
              data: (d) => Text(key: taskListTitleKey, d.name()),
              error: (e, s) => Text(L10n.of(context).failedToLoad(e)),
              loading: () => Text(L10n.of(context).loading),
            ),
          ],
        ),
      ),
      body: CenteredPage(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: task.when(
                data: (t) => TaskInfo(task: t),
                error: (e, s) => Text(L10n.of(context).failedToLoadTask(e)),
                loading: () => const TaskInfoSkeleton(),
                skipLoadingOnReload: true,
              ),
            ),
            // following: comments
          ],
        ),
      ),
    );
  }
}
