import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter/common/extensions/options.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

class TaskStatusWidget extends StatelessWidget {
  final Task task;
  final double? size;
  final Function()? onDone;

  const TaskStatusWidget({
    super.key,
    required this.task,
    this.size,
    this.onDone,
  });

  static Key doneKey(String taskId) {
    return Key('task-entry-$taskId-status-btn-done');
  }

  static Key notDoneKey(String taskId) {
    return Key('task-entry-$taskId-status-btn-not-done');
  }

  @override
  Widget build(BuildContext context) {
    final isDone = task.isDone();
    final taskId = task.eventIdStr();

    return InkWell(
      key: isDone ? doneKey(taskId) : notDoneKey(taskId),
      child: Icon(
        isDone ? Atlas.check_circle_thin : Icons.radio_button_off_outlined,
        size: size,
      ),
      onTap: () async {
        final updater = task.updateBuilder();
        if (!isDone) {
          updater.markDone();
        } else {
          updater.markUndone();
        }
        await updater.send();
        onDone.map((cb) => cb());
      },
    );
  }
}
