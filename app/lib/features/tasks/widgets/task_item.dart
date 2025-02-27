import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/room/room_avatar_builder.dart';
import 'package:acter/features/tasks/providers/task_items_providers.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter/features/tasks/widgets/task_status_widget.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:dart_date/dart_date.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::tasks::widgets::task_item');

class TaskItem extends ConsumerWidget {
  final String taskListId;
  final String taskId;
  final bool showBreadCrumb;
  final Function()? onDone;
  final Function()? onTap;

  const TaskItem({
    super.key,
    required this.taskListId,
    required this.taskId,
    this.showBreadCrumb = false,
    this.onDone,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final taskLoader = ref.watch(
      taskItemProvider((taskListId: taskListId, taskId: taskId)),
    );
    return taskLoader.when(
      data:
          (task) => ListTile(
            onTap: () {
              context.pushNamed(
                Routes.taskItemDetails.name,
                pathParameters: {'taskId': taskId, 'taskListId': taskListId},
              );
            },
            horizontalTitleGap: 0,
            minVerticalPadding: 0,
            contentPadding: const EdgeInsets.all(3),
            visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
            minLeadingWidth: 35,
            leading: leadingWidget(task),
            title: takeItemTitle(context, task),
            subtitle: takeItemSubTitle(ref, context, task),
            trailing: trailing(ref, task),
          ),
      error: (e, s) {
        _log.severe('Failed to load task', e, s);
        // FIXME: don't show broken task list items on main screen;
        return const SizedBox.shrink();
        // // return ListTile(
        // //   title: Text(lang.loadingFailed(e)),
        // );
      },
      loading: () => ListTile(title: Text(lang.loading)),
    );
  }

  Widget takeItemTitle(BuildContext context, Task task) {
    final textTheme = Theme.of(context).textTheme;
    return Text(
      task.title(),
      style:
          task.isDone()
              ? textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w100,
                decoration: TextDecoration.lineThrough,
              )
              : textTheme.bodyMedium,
    );
  }

  Widget leadingWidget(Task task) =>
      TaskStatusWidget(task: task, onDone: onDone);

  Widget takeItemSubTitle(WidgetRef ref, BuildContext context, Task task) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    final description = task.description()?.body();
    final tasklistId = task.taskListIdStr();
    final tasklistLoader = ref.watch(taskListProvider(tasklistId));
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBreadCrumb)
            tasklistLoader.when(
              data:
                  (taskList) => Row(
                    children: [
                      const Icon(Icons.list, color: Colors.white54, size: 22),
                      const SizedBox(width: 6),
                      Text(taskList.name(), style: textTheme.labelMedium),
                    ],
                  ),
              error: (e, s) {
                _log.severe('Failed to load task', e, s);
                return Text(lang.loadingFailed(e));
              },
              loading: () => Skeletonizer(child: Text(lang.loading)),
            ),
          if (description != null && !showBreadCrumb)
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelMedium,
            ),
          dueDateWidget(context, task),
        ],
      ),
    );
  }

  Widget dueDateWidget(BuildContext context, Task task) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return task.dueDate().map((dueDate) {
          final date = DateTime.parse(dueDate);
          final dateText = DateFormat(
            DateFormat.YEAR_MONTH_WEEKDAY_DAY,
          ).format(date);
          final label =
              date.isToday
                  ? lang.dueToday
                  : date.isTomorrow
                  ? lang.dueTomorrow
                  : date.isPast
                  ? date.timeago()
                  : lang.due(dateText);
          final iconColor =
              date.isPast ? colorScheme.onSurface : Colors.white54;
          var textStyle = textTheme.labelMedium;
          if (date.isPast) {
            textStyle = textStyle?.copyWith(color: colorScheme.error);
          }
          return Row(
            children: [
              Icon(Icons.access_time, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Text(label, style: textStyle),
            ],
          );
        }) ??
        const SizedBox.shrink();
  }

  Widget? trailing(WidgetRef ref, Task task) {
    return showBreadCrumb
        ? RoomAvatarBuilder(roomId: task.roomIdStr(), avatarSize: 35)
        : taskAssignee(ref, task);
  }

  Widget? taskAssignee(WidgetRef ref, Task task) {
    final assignees = asDartStringList(task.assigneesStr());
    if (assignees.isEmpty) return null;

    final roomId = task.roomIdStr();
    final avatarInfo = ref.watch(
      memberAvatarInfoProvider((roomId: roomId, userId: assignees.first)),
    );

    return ActerAvatar(options: AvatarOptions.DM(avatarInfo, size: 16));
  }

  Key doneKey() {
    return Key('task-entry-$taskId-status-btn-done');
  }

  Key notDoneKey() {
    return Key('task-entry-$taskId-status-btn-not-done');
  }
}
