import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/room/room_avatar_builder.dart';
import 'package:acter/features/tasks/providers/task_items_providers.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:dart_date/dart_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::tasks::widget::task_item');

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
    return ref
        .watch(taskItemProvider((taskListId: taskListId, taskId: taskId)))
        .when(
          data: (task) => ListTile(
            onTap: () {
              context.pushNamed(
                Routes.taskItemDetails.name,
                pathParameters: {
                  'taskId': taskId,
                  'taskListId': taskListId,
                },
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
          error: (error, stack) {
            _log.severe('failed to load task', error, stack);
            return ListTile(
              title: Text('Loading of task failed: $error'),
            );
          },
          loading: () => const ListTile(
            title: Text('loading'),
          ),
        );
  }

  Widget takeItemTitle(BuildContext context, Task task) {
    return Text(
      task.title(),
      style: task.isDone()
          ? Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w100,
                decoration: TextDecoration.lineThrough,
              )
          : Theme.of(context).textTheme.bodyMedium!,
    );
  }

  Widget leadingWidget(Task task) {
    final isDone = task.isDone();
    return InkWell(
      key: isDone ? doneKey() : notDoneKey(),
      child: Icon(
        isDone ? Atlas.check_circle_thin : Icons.radio_button_off_outlined,
      ),
      onTap: () async {
        final updater = task.updateBuilder();
        if (!isDone) {
          updater.markDone();
        } else {
          updater.markUndone();
        }
        await updater.send();
        if (onDone != null) {
          onDone!();
        }
      },
    );
  }

  Widget takeItemSubTitle(WidgetRef ref, BuildContext context, Task task) {
    final description = task.description();
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBreadCrumb)
            ref.watch(taskListItemProvider(task.taskListIdStr())).when(
                  data: (taskList) => Row(
                    children: [
                      const Icon(
                        Icons.list,
                        color: Colors.white54,
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        taskList.name(),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                  error: (e, s) {
                    _log.severe('Loading of task failed', e, s);
                    return Text(L10n.of(context).loadingFailed(e));
                  },
                  loading: () => Skeletonizer(
                    child: Text(L10n.of(context).loading),
                  ),
                ),
          if (description?.body() != null && !showBreadCrumb)
            Text(
              description!.body(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          dueDateWidget(context, task),
        ],
      ),
    );
  }

  Widget dueDateWidget(BuildContext context, Task task) {
    TextStyle? textStyle = Theme.of(context).textTheme.labelMedium;
    DateTime? dueDate =
        task.dueDate() == null ? null : DateTime.parse(task.dueDate()!);

    if (dueDate == null) return const SizedBox.shrink();

    String? label;
    Color iconColor = Colors.white54;
    if (dueDate.isToday) {
      label = L10n.of(context).dueToday;
    } else if (dueDate.isTomorrow) {
      label = L10n.of(context).dueTomorrow;
    } else if (dueDate.isPast) {
      label = dueDate.timeago();
      iconColor = Theme.of(context).colorScheme.onSurface;
      textStyle = textStyle?.copyWith(
        color: Theme.of(context).colorScheme.error,
      );
    }
    final dateText =
        DateFormat(DateFormat.YEAR_MONTH_WEEKDAY_DAY).format(dueDate);

    return Row(
      children: [
        Icon(
          Icons.access_time,
          color: iconColor,
          size: 18,
        ),
        const SizedBox(width: 6),
        Text(
          label ?? L10n.of(context).due(dateText),
          style: textStyle,
        ),
      ],
    );
  }

  Widget? trailing(WidgetRef ref, Task task) {
    return showBreadCrumb
        ? RoomAvatarBuilder(
            roomId: task.roomIdStr(),
            avatarSize: 35,
          )
        : taskAssignee(ref, task);
  }

  Widget? taskAssignee(WidgetRef ref, Task task) {
    final assignees = task.assigneesStr().map((s) => s.toDartString()).toList();

    if (assignees.isEmpty) return null;

    final avatarInfo = ref.watch(
      memberAvatarInfoProvider(
        (roomId: task.roomIdStr(), userId: assignees.first),
      ),
    );

    return ActerAvatar(
      options: AvatarOptions.DM(
        avatarInfo,
        size: 16,
      ),
    );
  }

  Key doneKey() {
    return Key('task-entry-$taskId-status-btn-done');
  }

  Key notDoneKey() {
    return Key('task-entry-$taskId-status-btn-not-done');
  }
}
