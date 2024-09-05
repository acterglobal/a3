import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/acter_icon_picker/acter_icon_widget.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter/features/tasks/widgets/task_items_list_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::tasks::widget::task_list_item');

class TaskListItemCard extends ConsumerWidget {
  final String taskListId;
  final bool showSpace;
  final bool showCompletedTask;
  final bool initiallyExpanded;

  const TaskListItemCard({
    super.key,
    required this.taskListId,
    this.showSpace = false,
    this.showCompletedTask = false,
    this.initiallyExpanded = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasklistLoader = ref.watch(taskListItemProvider(taskListId));
    return tasklistLoader.when(
      data: (taskList) => Card(
        key: Key('task-list-card-$taskListId'),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          leading: ActerIconWidget(
            iconSize: 25,
            color: convertColor(
              taskList.display()?.color(),
              Theme.of(context).unselectedWidgetColor,
            ),
            icon: ActerIcon.iconForTask(taskList.display()?.iconStr()),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          iconColor: Theme.of(context).colorScheme.onSurface,
          childrenPadding: const EdgeInsets.symmetric(horizontal: 10),
          title: title(context, taskList),
          subtitle: subtitle(ref, taskList),
          children: [
            TaskItemsListWidget(
              taskList: taskList,
              showCompletedTask: showCompletedTask,
            ),
          ],
        ),
      ),
      error: (e, s) {
        _log.severe('Failed to load tasklist', e, s);
        return Card(
          child: Text(L10n.of(context).errorLoadingTasks(e)),
        );
      },
      loading: () => Card(
        child: Text(L10n.of(context).loading),
      ),
    );
  }

  Widget title(BuildContext context, TaskList taskList) {
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

  Widget? subtitle(WidgetRef ref, TaskList taskList) {
    final spaceId = taskList.spaceIdStr();
    final spaceProfile = ref.watch(roomAvatarInfoProvider(spaceId));
    return showSpace ? Text(spaceProfile.displayName ?? '') : null;
  }
}
