import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jiffy/jiffy.dart';

class TaskEntry extends ConsumerWidget {
  final Task task;
  const TaskEntry({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Widget> subtitle = [];
    final dueDate = task.utcDueRfc3339();
    if (dueDate != null) {
      final due = Jiffy.parse(dueDate);
      final now = Jiffy.now();
      if (due.isBefore(now)) {
        subtitle.add(
          Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Text(
              due.fromNow(),
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(context).colorScheme.taskOverdueFG,
                    backgroundColor:
                        Theme.of(context).colorScheme.taskOverdueBG,
                  ),
            ),
          ),
        );
      } else {
        // FIXME: HL today, tomorrow
        subtitle.add(
          Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Text(
              due.fromNow(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        );
      }
    }
    final assignees = task.assignees();
    if (assignees.isNotEmpty) {}
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
      leading: Checkbox(
        value: task.isDone(),
        onChanged: (bool? value) async {
          final updater = task.updateBuilder();
          if (value == true) {
            updater.markDone();
          } else {
            updater.markUndone();
          }
          await updater.send();
        },
      ),
      title: Text(
        task.title(),
        style: Theme.of(context)
            .textTheme
            .bodyMedium!
            .copyWith(fontWeight: FontWeight.normal),
      ),
      subtitle: subtitle.isEmpty ? null : Row(children: subtitle),
    );
  }
}
