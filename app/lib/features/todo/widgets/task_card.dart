import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/todo/controllers/todo_controller.dart';
import 'package:acter/models/ToDoList.dart';
import 'package:acter/models/ToDoTask.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TaskCard extends StatelessWidget {
  final ToDoController controller;
  final ToDoTask task;
  final ToDoList todoList;

  const TaskCard({
    super.key,
    required this.controller,
    required this.task,
    required this.todoList,
  });

  Future<void> _handleUpdate() async {
    var eventId = await controller.updateToDoTask(
      task,
      todoList,
      null,
      null,
      null,
    );
    debugPrint('TOGGLE CHECK: $eventId');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.tertiary3,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Flexible(
                  child: InkWell(
                    onTap: _handleUpdate,
                    child: _CheckWidget(task: task),
                  ),
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      task.name,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: task.progressPercent >= 100
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                task.due != null
                    ? const Icon(Atlas.calendar_dots)
                    : const SizedBox.shrink(),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: task.due != null
                      ? Text(
                          task.progressPercent >= 100
                              ? DateFormat('H:mm E, d MMM')
                                  .format(task.due!.toUtc())
                              : DateFormat('E, d MMM')
                                  .format(task.due!.toUtc()),
                        )
                      : const SizedBox.shrink(),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Visibility(
                    visible: task.commentsManager.hasComments(),
                    child: Row(
                      children: <Widget>[
                        const Icon(Atlas.dots_horizontal, color: Colors.grey),
                        const Icon(Atlas.message),
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            '${task.commentsManager.commentsCount()}',
                          ),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckWidget extends StatelessWidget {
  final ToDoTask task;

  const _CheckWidget({required this.task});

  @override
  Widget build(BuildContext context) {
    if ((task.progressPercent < 100)) {
      return const Icon(
        Atlas.check_circle_thin,
      );
    }
    return Icon(
      Atlas.check_circle_thin,
      color: Theme.of(context).colorScheme.tertiary,
    );
  }
}
