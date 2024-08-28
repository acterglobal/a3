import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/home/providers/task_providers.dart';
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
    final tasksLoader = ref.watch(myOpenTasksProvider);
    return tasksLoader.when(
      data: (tasks) {
        if (tasks.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            myTaskHeader(context),
            ListView.separated(
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
                  onDone: () => EasyLoading.showToast(
                    L10n.of(context).markedAsDone,
                  ),
                );
              },
            ),
          ],
        );
      },
      error: (e, s) {
        _log.severe('Failed to load open tasks', e, s);
        return Text(L10n.of(context).loadingTasksFailed(e));
      },
      loading: () => Text(L10n.of(context).loading),
    );
  }

  Widget myTaskHeader(BuildContext context) {
    return Row(
      children: [
        Text(
          L10n.of(context).myTasks,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const Spacer(),
        ActerInlineTextButton(
          onPressed: () => context.pushNamed(Routes.tasks.name),
          child: Text(L10n.of(context).seeAll),
        ),
      ],
    );
  }
}
