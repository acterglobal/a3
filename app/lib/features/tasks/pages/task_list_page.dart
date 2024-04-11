import 'package:acter/common/widgets/centered_page.dart';
import 'package:acter/common/widgets/icons/tasks_icon.dart';
import 'package:acter/features/tasks/providers/tasklists.dart';
import 'package:acter/features/tasks/widgets/task_list_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskListPage extends ConsumerWidget {
  static const taskListTitleKey = Key('task-list-title');
  static const pageKey = Key('task-list-page');
  final String taskListId;

  const TaskListPage({
    Key key = pageKey,
    required this.taskListId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskList = ref.watch(taskListProvider(taskListId));
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
              child: taskList.maybeWhen(
                data: (taskList) => TaskListCard(
                  taskList: taskList,
                  showDescription: true,
                  showTitle: false,
                  showAttachmentsAndComments: true,
                ),
                orElse: () => Text(L10n.of(context).loading),
              ),
              // following: comments
            ),
          ],
        ),
      ),
    );
  }
}
