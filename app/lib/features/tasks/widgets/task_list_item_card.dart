import 'package:acter/common/providers/room_providers.dart';
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
  final bool initiallyExpanded;

  const TaskListItemCard({
    super.key,
    required this.taskList,
    this.showSpace = false,
    this.showCompletedTask = false,
    this.initiallyExpanded = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskListId = taskList.eventIdStr();
    return Card(
      key: Key('task-list-card-$taskListId'),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        iconColor: Theme.of(context).colorScheme.onSurface,
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
    final spaceProfile =
        ref.watch(roomAvatarInfoProvider(taskList.spaceIdStr()));

    return showSpace ? Text(spaceProfile.displayName ?? '') : null;
  }
}
