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
    final sortedTasks = ref.watch(sortedTasksProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(lang.myTasks)),
      body: sortedTasks?.totalCount == 0
          ? Center(
              child: Text(
                lang.noTasks,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                if (sortedTasks?.hasTasksInCategory(TaskDueCategory.overdue) ?? false)
                  _buildTaskSection(
                    context,
                    title: lang.overdue,
                    tasks: sortedTasks!.overdue,
                    icon: Icons.warning_amber_rounded,
                    color: Theme.of(context).colorScheme.error,
                  ),
                if (sortedTasks?.hasTasksInCategory(TaskDueCategory.today) ?? false)
                  _buildTaskSection(
                    context,
                    title: lang.today,
                    tasks: sortedTasks!.today,
                    icon: Icons.today_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                if (sortedTasks?.hasTasksInCategory(TaskDueCategory.tomorrow) ?? false)
                  _buildTaskSection(
                    context,
                    title: lang.tomorrow,
                    tasks: sortedTasks!.tomorrow,
                    icon: Icons.event_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                if (sortedTasks?.hasTasksInCategory(TaskDueCategory.laterThisWeek) ?? false)
                  _buildTaskSection(
                    context,
                    title: lang.laterThisWeek,
                    tasks: sortedTasks!.laterThisWeek,
                    icon: Icons.calendar_month_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                if (sortedTasks?.hasTasksInCategory(TaskDueCategory.later) ?? false)
                  _buildTaskSection(
                    context,
                    title: lang.later,
                    tasks: sortedTasks!.later,
                    icon: Icons.event_note_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                if (sortedTasks?.hasTasksInCategory(TaskDueCategory.noDueDate) ?? false)
                  _buildTaskSection(
                    context,
                    title: lang.noDueDate,
                    tasks: sortedTasks!.noDueDate,
                    icon: Icons.event_busy_rounded,
                    color: Theme.of(context).colorScheme.outline,
                  ),
              ],
            ),
    );
  }

  Widget _buildTaskSection(
    BuildContext context, {
    required String title,
    required List<Task> tasks,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTaskSectionHeader(
          context,
          title: title,
          icon: icon,
          color: color,
        ),
        _buildTaskSectionBody(context, tasks: tasks),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTaskSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskSectionBody(BuildContext context, {required List<Task> tasks}) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) =>
          const Divider(color: Colors.white24, indent: 30),
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

