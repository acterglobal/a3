import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/tasks/widgets/task_items_list_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TaskListItemCard extends ConsumerWidget {
  final TaskList taskList;
  final bool showSpace;
  final bool showCompletedTask;

  const TaskListItemCard({
    super.key,
    required this.taskList,
    this.showSpace = false,
    this.showCompletedTask = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      key: Key('task-list-card-${taskList.eventIdStr()}'),
      child: ExpansionTile(
        initiallyExpanded: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        iconColor: Theme.of(context).colorScheme.neutral6,
        childrenPadding: const EdgeInsets.symmetric(horizontal: 10),
        title: title(context),
        subtitle: subtitle(ref),
        children: [
          TaskItemsListWidget(
            taskList: taskList,
            showCompletedTask: showCompletedTask,
          ),
        ],
      ),
    );
  }

  Widget title(BuildContext context) {
    final taskListId = taskList.eventIdStr();
    return InkWell(
      onTap: () {
        context.pushNamed(
          Routes.taskListDetails.name,
          pathParameters: {'taskListId': taskListId},
        );
      },
      child: Text(
        key: Key('task-list-title-$taskListId'),
        taskList.name(),
      ),
    );
  }

  Widget? subtitle(WidgetRef ref) {
    final spaceProfile = ref
        .watch(spaceProfileDataForSpaceIdProvider(taskList.spaceIdStr()))
        .valueOrNull;

    return showSpace && spaceProfile != null
        ? Text(spaceProfile.profile.displayName ?? '')
        : null;
  }
}
