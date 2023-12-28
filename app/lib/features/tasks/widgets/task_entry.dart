import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/tasks/providers/tasks.dart';
import 'package:acter/features/tasks/widgets/due_chip.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TaskEntry extends ConsumerWidget {
  final Task task;
  final bool showBreadCrumb;
  final Function()? onDone;
  const TaskEntry({
    Key? key,
    required this.task,
    this.showBreadCrumb = false,
    this.onDone,
  }) : super(key: key);

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
        builder: (context, ref, child) =>
            ref.watch(taskCommentsProvider(task)).when(
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
                  error: (e, s) => Text('loading comments failed: $e'),
                  loading: () => const SizedBox.shrink(),
                ),
      ),
    );

    return ListTile(
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
          padding: const EdgeInsets.only(right: 5),
          child: Icon(
            isDone ? Atlas.check_circle_thin : Icons.radio_button_off_outlined,
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
          children: [
            Text(
              task.title(),
              style: isDone
                  ? Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontWeight: FontWeight.w100,
                        color: AppTheme.brandColorScheme.neutral5,
                      )
                  : Theme.of(context).textTheme.bodyMedium!,
            ),
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
