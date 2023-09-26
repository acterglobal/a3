import 'package:acter/features/tasks/providers/tasks.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jiffy/jiffy.dart';

class TaskEntry extends ConsumerWidget {
  final Task task;
  const TaskEntry({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Widget> extraInfo = [];
    final dueDate = task.utcDueRfc3339();
    final isDone = task.isDone();
    if (!isDone) {
      if (dueDate != null) {
        final due = Jiffy.parse(dueDate);
        final now = Jiffy.now();
        if (due.isBefore(now)) {
          extraInfo.add(
            Padding(
              padding: const EdgeInsets.only(left: 3),
              child: Tooltip(
                message: due.format(),
                child: Text(
                  due.fromNow(),
                  style: isDone
                      ? null
                      : Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: Theme.of(context).colorScheme.taskOverdueFG,
                          ),
                ),
              ),
            ),
          );
        } else {
          // FIXME: HL today, tomorrow
          extraInfo.add(
            Padding(
              padding: const EdgeInsets.only(left: 3),
              child: Text(
                due.fromNow(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          );
        }
      }
    }
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
        },
      ),
      title: Row(
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
    );
  }
}
