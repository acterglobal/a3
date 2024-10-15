import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter/features/tasks/widgets/task_list_item_card.dart';
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
    final lang = L10n.of(context);
    final tasksLoader = ref.watch(taskListProvider(spaceId));
    return tasksLoader.when(
      data: (tasks) => buildTasksSectionUI(context, tasks),
      error: (e, s) {
        _log.severe('Failed to load tasks in space', e, s);
        return Center(
          child: Text(lang.loadingTasksFailed(e)),
        );
      },
      loading: () => Center(
        child: Text(lang.loading),
      ),
    );
  }

  Widget buildTasksSectionUI(BuildContext context, List<String> tasks) {
    final hasMore = tasks.length > limit;
    final count = hasMore ? limit : tasks.length;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: L10n.of(context).tasks,
          isShowSeeAllButton: hasMore,
          onTapSeeAll: () => context.pushNamed(
            Routes.spaceTasks.name,
            pathParameters: {'spaceId': spaceId},
          ),
        ),
        taskListUI(tasks, count),
      ],
    );
  }

  Widget taskListUI(List<String> tasks, int count) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: count,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => TaskListItemCard(
        taskListId: tasks[index],
        initiallyExpanded: false,
      ),
    );
  }
}
