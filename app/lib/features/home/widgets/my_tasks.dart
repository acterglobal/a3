import 'package:acter/router/routes.dart';
import 'package:acter/features/home/providers/task_providers.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:acter/features/tasks/widgets/task_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::home::my_tasks');

class MyTasksSection extends ConsumerWidget {
  final int limit;

  const MyTasksSection({super.key, required this.limit});      

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final sortedTasksLoader = ref.watch(sortedTasksProvider);
    
    return sortedTasksLoader.when(
      data: (sortedTasks) {
        if (sortedTasks.totalCount == 0) return const SizedBox.shrink();

        // Get tasks in priority order
        final tasksToShow = [
          ...sortedTasks.overdue,
          ...sortedTasks.today,
          ...sortedTasks.tomorrow,
          ...sortedTasks.laterThisWeek,
          ...sortedTasks.later,
          ...sortedTasks.noDueDate,
        ].take(limit).toList();

        if (tasksToShow.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: lang.myTasks,
              showSectionBg: false,
              isShowSeeAllButton: true,
              onTapSeeAll: () => context.pushNamed(Routes.tasks.name),
            ),
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
                  taskListId: task.taskListIdStr(),
                  taskId: task.eventIdStr(),
                  showBreadCrumb: true,
                  onDone: () => EasyLoading.showToast(lang.markedAsDone),
                );
              },
            ),
            if (sortedTasks.totalCount > limit)
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 8),
                child: TextButton(
                  onPressed: () => context.pushNamed(Routes.myTasks.name),
                  child: Text(
                    lang.countMoreTasks(sortedTasks.totalCount - limit),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      error: (e, s) {
        _log.severe('Failed to load open tasks', e, s);
        return Text(lang.loadingTasksFailed(e));
      },
      loading: () => Text(lang.loading),
    );
  }
}
