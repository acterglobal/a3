import 'package:acter/features/attachments/widgets/attachment_section.dart';
import 'package:acter/features/comments/widgets/comments_section.dart';
import 'package:acter/features/tasks/providers/tasklists.dart';
import 'package:acter/features/tasks/widgets/task_items_list_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskListDetailPage extends ConsumerStatefulWidget {
  static const pageKey = Key('task-list-details-page');
  static const taskListTitleKey = Key('task-list-title');
  final String taskListId;

  const TaskListDetailPage({
    Key key = pageKey,
    required this.taskListId,
  }) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TaskListPageState();
}

class _TaskListPageState extends ConsumerState<TaskListDetailPage> {
  ValueNotifier<bool> showCompletedTask = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppbar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppbar() {
    final taskList = ref.watch(taskListProvider(widget.taskListId));
    return AppBar(
      title: taskList.when(
        data: (d) => Text(
          key: TaskListDetailPage.taskListTitleKey,
          d.name(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        error: (e, s) => Text(L10n.of(context).failedToLoad(e)),
        loading: () => Text(L10n.of(context).loading),
      ),
    );
  }

  Widget _buildBody() {
    final taskList = ref.watch(taskListProvider(widget.taskListId));
    return taskList.when(
      data: (data) => _buildTaskListData(data),
      error: (e, s) => Text(L10n.of(context).failedToLoad(e)),
      loading: () => Text(L10n.of(context).loading),
    );
  }

  Widget _buildTaskListData(TaskList taskListData) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _widgetDescription(taskListData),
            _widgetTasksList(taskListData),
          ],
        ),
      ),
    );
  }

  Widget _widgetDescription(TaskList taskListData) {
    if (taskListData.description() == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          taskListData.description()!.body(),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 10),
        const Divider(indent: 10, endIndent: 18),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _widgetTasksList(TaskList taskListData) {
    return Column(
      children: [
        _widgetTasksListHeader(),
        ValueListenableBuilder(
          valueListenable: showCompletedTask,
          builder: (context, value, child) {
            return TaskItemsListWidget(
              taskList: taskListData,
              showCompletedTask: value,
            );
          },
        ),
        const SizedBox(height: 20),
        AttachmentSectionWidget(manager: taskListData.attachments()),
        const SizedBox(height: 20),
        CommentsSection(manager: taskListData.comments()),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _widgetTasksListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          L10n.of(context).tasks,
        ),
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
      ],
    );
  }
}
