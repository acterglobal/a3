import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter/features/tasks/widgets/task_list_item_card.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::space::sections::tasks');

class TasksSection extends ConsumerWidget {
  final String spaceId;
  final int limit;

  const TasksSection({
    super.key,
    required this.spaceId,
    this.limit = 3,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskList = ref.watch(taskListProvider(spaceId));
    return taskList.when(
      data: (tasks) => buildTasksSectionUI(context, tasks),
      error: (error, stack) {
        _log.severe('Fetching of tasks failed', error, stack);
        return Center(
          child: Text(L10n.of(context).loadingFailed(error)),
        );
      },
      loading: () => Center(
        child: Text(L10n.of(context).loading),
      ),
    );
  }

  Widget buildTasksSectionUI(BuildContext context, List<TaskList> tasks) {
    int taskLimit = (tasks.length > limit) ? limit : tasks.length;
    bool isShowSeeAllButton = tasks.length > taskLimit;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: L10n.of(context).tasks,
          isShowSeeAllButton: isShowSeeAllButton,
          onTapSeeAll: () => context.pushNamed(
            Routes.spaceTasks.name,
            pathParameters: {'spaceId': spaceId},
          ),
        ),
        taskListUI(tasks, taskLimit),
      ],
    );
  }

  Widget taskListUI(List<TaskList> tasks, int taskLimit) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: taskLimit,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return TaskListItemCard(
          taskList: tasks[index],
          initiallyExpanded: false,
        );
      },
    );
  }
}
