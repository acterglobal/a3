import 'package:acter/router/routes.dart';
import 'package:acter/features/home/providers/task_providers.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:acter/features/tasks/widgets/task_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MyTasksSection extends ConsumerWidget {
  final int limit;

  const MyTasksSection({super.key, required this.limit});      

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final sortedTasks = ref.watch(sortedTasksProvider).value;
    ref.watch(myOpenTasksProvider); 
    
    if (sortedTasks?.totalCount == 0) return const SizedBox.shrink();

    // Get tasks in priority order
    final tasksToShow = [
      ...?sortedTasks?.overdue,
      ...?sortedTasks?.today,
      ...?sortedTasks?.tomorrow,
      ...?sortedTasks?.laterThisWeek,
      ...?sortedTasks?.later,
      ...?sortedTasks?.noDueDate,
    ].take(limit).toList();

    if (tasksToShow.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: lang.myTasks,
          showSectionBg: false,
          isShowSeeAllButton: true,
          onTapSeeAll: () => context.pushNamed(Routes.myTasks.name),
        ),
        const SizedBox(height: 10),
        ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (context, index) =>
              const Divider(color: Colors.white24, indent: 30),
          itemCount: tasksToShow.length,
          itemBuilder: (context, index) {
            final task = tasksToShow[index];
            return TaskItem(
              key: ValueKey('${task.eventIdStr()}-${task.dueDate()}'), // Unique key for rebuild
              taskListId: task.taskListIdStr(),
              taskId: task.eventIdStr(),
              showBreadCrumb: true,
              onDone: () => EasyLoading.showToast(lang.markedAsDone),
            );
          },
        ),
        if ((sortedTasks?.totalCount ?? 0) > limit)
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 8, bottom: 10),
            child: TextButton(
              onPressed: () => context.pushNamed(Routes.myTasks.name),
              child: Text(
                lang.countMoreTasks((sortedTasks?.totalCount ?? 0) - limit),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
