import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/home/providers/task_providers.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:acter/features/tasks/widgets/task_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::home::my_tasks');

class MyTasksSection extends ConsumerWidget {
  final int limit;

  const MyTasksSection({
    super.key,
    required this.limit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final tasksLoader = ref.watch(myOpenTasksProvider);
    return tasksLoader.when(
      data: (tasks) {
        if (tasks.isEmpty) return const SizedBox.shrink();
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
              separatorBuilder: (context, index) => const Divider(
                color: Colors.white24,
                indent: 30,
              ),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return TaskItem(
                  taskListId: tasks[index].taskListIdStr(),
                  taskId: tasks[index].eventIdStr(),
                  showBreadCrumb: true,
                  onDone: () => EasyLoading.showToast(lang.markedAsDone),
                );
              },
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
