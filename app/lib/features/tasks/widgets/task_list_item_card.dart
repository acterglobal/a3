import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/acter_icon_picker/acter_icon_widget.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/color_data.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter/features/tasks/widgets/task_items_list_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::tasks::widgets::task_list_item_card');

class TaskListItemCard extends ConsumerWidget {
  final String taskListId;
  final bool showSpace;
  final bool showCompletedTask;
  final bool showOnlyTaskList;
  final bool initiallyExpanded;
  final bool canExpand;
  final GestureTapCallback? onTitleTap;

  const TaskListItemCard({
    super.key,
    required this.taskListId,
    this.showSpace = false,
    this.showCompletedTask = false,
    this.showOnlyTaskList = false,
    this.initiallyExpanded = true,
    this.canExpand = true,
    this.onTitleTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final tasklistLoader = ref.watch(taskListProvider(taskListId));
    return tasklistLoader.when(
      data: (taskList) => Card(
        key: Key('task-list-card-$taskListId'),
        child: canExpand
            ? expandable(context, ref, taskList)
            : simple(context, ref, taskList),
      ),
      error: (e, s) {
        _log.severe('Failed to load tasklist', e, s);
        return Card(
          child: Text(lang.errorLoadingTasks(e)),
        );
      },
      loading: () => Card(
        child: Text(lang.loading),
      ),
    );
  }

  Widget expandable(BuildContext context, WidgetRef ref, TaskList taskList) =>
      ExpansionTile(
        trailing: showOnlyTaskList ? const SizedBox() : null,
        initiallyExpanded: initiallyExpanded,
        leading: ActerIconWidget(
          iconSize: 30,
          color: convertColor(
            taskList.display()?.color(),
            iconPickerColors[0],
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
        children: showOnlyTaskList
            ? []
            : [
                TaskItemsListWidget(
                  taskList: taskList,
                  showCompletedTask: showCompletedTask,
                ),
              ],
      );

  Widget simple(BuildContext context, WidgetRef ref, TaskList taskList) =>
      ListTile(
        leading: ActerIconWidget(
          iconSize: 30,
          color: convertColor(
            taskList.display()?.color(),
            iconPickerColors[0],
          ),
          icon: ActerIcon.iconForTask(taskList.display()?.iconStr()),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        iconColor: Theme.of(context).colorScheme.onSurface,
        title: title(context, taskList),
        subtitle: subtitle(ref, taskList),
      );

  Widget title(BuildContext context, TaskList taskList) {
    return InkWell(
      onTap: onTitleTap ??
          () {
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
    if (!showSpace) return null;
    return SpaceChip(spaceId: taskList.spaceIdStr(), useCompactView: true);
  }
}
