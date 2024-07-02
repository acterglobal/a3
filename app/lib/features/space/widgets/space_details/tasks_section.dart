import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/features/tasks/providers/tasklists.dart';
import 'package:acter/features/tasks/widgets/task_list_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

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
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tasksLabel(context),
        tasksList(context, ref),
      ],
    );
  }

  Widget tasksLabel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Text(
            L10n.of(context).tasks,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Spacer(),
          ActerInlineTextButton(
            onPressed: () {},
            child: Text(L10n.of(context).seeAll),
          ),
        ],
      ),
    );
  }

  Widget tasksList(BuildContext context, WidgetRef ref) {
    final taskList = ref.watch(spaceTasksListsProvider(spaceId));

    return taskList.when(
      data: (task) {
        int taskLimit = (task.length > limit) ? limit : task.length;
        return ListView.builder(
          shrinkWrap: true,
          itemCount: taskLimit,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return TaskListItemCard(
              taskList: task[index],
              initiallyExpanded: false,
            );
          },
        );
      },
      error: (error, stack) =>
          Center(child: Text(L10n.of(context).loadingFailed(error))),
      loading: () => Center(
        child: Text(L10n.of(context).loading),
      ),
    );
  }
}
