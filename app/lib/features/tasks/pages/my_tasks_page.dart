import 'package:acter/features/home/providers/task_providers.dart';
import 'package:acter/features/tasks/actions/my_task_actions.dart';
import 'package:acter/features/tasks/widgets/task_item.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyTasksPage extends ConsumerWidget {
  const MyTasksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final sortedTasks = ref.watch(sortedTasksProvider).valueOrNull;

    if (sortedTasks == null) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(title: Text(lang.myTasks)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          if (sortedTasks.hasTasksInCategory(TaskDueCategory.overdue))
            _buildTaskSection(
              context,
              title: lang.overdue,
              tasks: sortedTasks.overdue,
              sectionHeaderStyle: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
          if (sortedTasks.hasTasksInCategory(TaskDueCategory.today))
            _buildTaskSection(
              context,
              title: lang.today,
              tasks: sortedTasks.today,
              sectionHeaderStyle: Theme.of(context).textTheme.titleSmall,
            ),
          if (sortedTasks.hasTasksInCategory(TaskDueCategory.tomorrow))
            _buildTaskSection(
              context,
              title: lang.tomorrow,
              tasks: sortedTasks.tomorrow,
            ),
          if (sortedTasks.hasTasksInCategory(TaskDueCategory.laterThisWeek))
            _buildTaskSection(
              context,
              title: lang.laterThisWeek,
              tasks: sortedTasks.laterThisWeek,
            ),
          if (sortedTasks.hasTasksInCategory(TaskDueCategory.later))
            _buildTaskSection(
              context,
              title: lang.later,
              tasks: sortedTasks.later,
            ),
          if (sortedTasks.hasTasksInCategory(TaskDueCategory.noDueDate))
            _buildTaskSection(
              context,
              title: lang.noDueDate,
              tasks: sortedTasks.noDueDate,
            ),
        ],
      ),
    );
  }

  Widget _buildTaskSection(
    BuildContext context, {
    required String title,
    required List<Task> tasks,
    TextStyle? sectionHeaderStyle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTaskSectionHeader(
          context,
          title: title,
          sectionHeaderStyle: sectionHeaderStyle,
        ),
        _buildTaskSectionBody(context, tasks: tasks),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTaskSectionHeader(
    BuildContext context, {
    required String title,
    TextStyle? sectionHeaderStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            title,
            style:
                sectionHeaderStyle ?? Theme.of(context).textTheme.labelMedium,
          ),
          Expanded(child: const Divider(color: Colors.white24, indent: 12)),
        ],
      ),
    );
  }

  Widget _buildTaskSectionBody(
    BuildContext context, {
    required List<Task> tasks,
  }) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder:
          (context, index) => const Divider(color: Colors.white12, indent: 30),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskItem(
          taskListId: task.taskListIdStr(),
          taskId: task.eventIdStr(),
          showBreadCrumb: true,
          onDone: () => EasyLoading.showToast(L10n.of(context).markedAsDone),
        );
      },
    );
  }
}
