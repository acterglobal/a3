import 'package:acter/common/widgets/render_html.dart';
import 'package:acter/features/tasks/providers/tasks.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jiffy/jiffy.dart';

class TaskInfo extends ConsumerWidget {
  static const statusBtnNotDone = Key('task-info-status-not-done');
  static const statusBtnDone = Key('task-info-status-done');
  final Task task;
  const TaskInfo({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Widget> body = [];
    final dueDate = task.utcDueRfc3339();
    final isDone = task.isDone();
    if (!isDone) {
      if (dueDate != null) {
        final due = Jiffy.parse(dueDate);
        final now = Jiffy.now();
        if (due.isBefore(now)) {
          body.add(
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
          body.add(
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
      final formattedBody = description.formattedBody();
      if (formattedBody != null && formattedBody.isNotEmpty) {
        body.add(RenderHtml(text: formattedBody));
      } else {
        final str = description.body();
        if (str.isNotEmpty) {
          body.add(Text(str));
        }
      }
    }
    body.add(
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

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: InkWell(
              key: isDone ? statusBtnDone : statusBtnNotDone,
              child: Padding(
                padding: const EdgeInsets.only(right: 5),
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
              },
            ),
            title: Wrap(
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
              ],
            ),
          ),
          ...body,
        ],
      ),
    );
  }
}
