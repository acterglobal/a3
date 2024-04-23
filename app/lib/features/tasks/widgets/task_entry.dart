import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/icons/tasks_icon.dart';
import 'package:acter/common/widgets/room/room_avatar_builder.dart';
import 'package:acter/features/tasks/providers/tasklists.dart';
import 'package:acter/features/tasks/providers/tasks.dart';
import 'package:acter/features/tasks/widgets/due_chip.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class TaskEntry extends ConsumerWidget {
  final Task task;
  final bool showBreadCrumb;
  final Function()? onDone;

  const TaskEntry({
    super.key,
    required this.task,
    this.showBreadCrumb = false,
    this.onDone,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Widget> extraInfo = [DueChip(task: task)];
    final isDone = task.isDone();
    final description = task.description();
    if (description != null) {
      extraInfo.add(
        Tooltip(
          message: description.body(),
          child: const Icon(Atlas.document_thin),
        ),
      );
    }
    extraInfo.add(
      Consumer(
        builder: (context, ref, child) => ref
            .watch(taskCommentsProvider(task))
            .when(
              data: (commentsManager) {
                if (!commentsManager.hasComments()) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: Wrap(
                    children: [
                      const Icon(Atlas.comment_thin),
                      Text(
                        commentsManager.commentsCount().toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              },
              error: (e, s) => Text(L10n.of(context).loadingCommentsFailed(e)),
              loading: () => const SizedBox.shrink(),
            ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: ListTile(
        horizontalTitleGap: 0,
        minVerticalPadding: 0,
        contentPadding: const EdgeInsets.all(0),
        visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
        style: ListTileTheme.of(context)
            .copyWith(
              contentPadding: const EdgeInsets.all(0),
              visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
              minVerticalPadding: 0,
            )
            .style,
        leading: InkWell(
          key: isDone ? doneKey() : notDoneKey(),
          child: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Icon(
              isDone
                  ? Atlas.check_circle_thin
                  : Icons.radio_button_off_outlined,
            ),
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
        ),
        title: InkWell(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                task.title(),
                style: isDone
                    ? Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w100,
                        )
                    : Theme.of(context).textTheme.bodyMedium!,
              ),
              const SizedBox(width: 12),
              ...extraInfo,
            ],
          ),
          onTap: () {
            context.pushNamed(
              Routes.task.name,
              pathParameters: {
                'taskId': task.eventIdStr(),
                'taskListId': task.taskListIdStr(),
              },
            );
          },
        ),
        subtitle: showBreadCrumb
            ? Wrap(
                children: [
                  RoomAvatarBuilder(
                    roomId: task.roomIdStr(),
                    avatarSize: 19,
                  ),
                  const TasksIcon(size: 19),
                  ref.watch(taskListProvider(task.taskListIdStr())).when(
                        data: (tl) => Text(tl.name()),
                        error: (e, s) =>
                            Text(L10n.of(context).loadingFailed(e)),
                        loading: () => Skeletonizer(
                          child: Text(L10n.of(context).loading),
                        ),
                      ),
                ],
              )
            : null,
      ),
    );
  }

  Key doneKey() {
    final taskId = task.eventIdStr();
    return Key('task-entry-$taskId-status-btn-done');
  }

  Key notDoneKey() {
    final taskId = task.eventIdStr();
    return Key('task-entry-$taskId-status-btn-not-done');
  }
}
