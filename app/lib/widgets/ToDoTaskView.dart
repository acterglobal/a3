import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/todo_controller.dart';
import 'package:effektio/models/ToDoList.dart';
import 'package:effektio/models/ToDoTask.dart';
import 'package:effektio/screens/HomeScreens/todo/TaskDetailScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class ToDoTaskView extends StatefulWidget {
  final ToDoTask task;
  final ToDoList todoList;
  final ToDoController controller;
  const ToDoTaskView({
    Key? key,
    required this.task,
    required this.todoList,
    required this.controller,
  }) : super(key: key);

  @override
  State<ToDoTaskView> createState() => _ToDoTaskViewState();
}

class _ToDoTaskViewState extends State<ToDoTaskView> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ToDoTaskDetailScreen(
            task: widget.task,
            list: widget.todoList,
            controller: widget.controller,
          ),
        ),
      ),
      child: TaskCard(
        task: widget.task,
        controller: widget.controller,
        todoList: widget.todoList,
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.todoList,
    required this.controller,
  });
  final ToDoTask task;
  final ToDoList todoList;
  final ToDoController controller;
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: ToDoTheme.secondaryCardColor,
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
                    onTap: () async => await controller
                        .updateToDoTask(task, todoList, null, null)
                        .then((res) => debugPrint('TOGGLE CHECK')),
                    child: CircleAvatar(
                      backgroundColor: AppCommonTheme.transparentColor,
                      radius: 18,
                      child: Container(
                        height: 25,
                        width: 25,
                        decoration: BoxDecoration(
                          color: (task.progressPercent >= 100)
                              ? ToDoTheme.activeCheckColor
                              : ToDoTheme.inactiveCheckColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: 1.5,
                            color: ToDoTheme.floatingABColor,
                          ),
                        ),
                        child: _CheckWidget(task: task),
                      ),
                    ),
                  ),
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      task.name,
                      style: ToDoTheme.taskTitleTextStyle.copyWith(
                        decoration: (task.progressPercent >= 100)
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      overflow: TextOverflow.ellipsis,
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
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                  child: Visibility(
                    visible: task.progressPercent >= 100,
                    child: const Icon(
                      FlutterIcons.ios_checkmark_circle_outline_ion,
                      color: Colors.red,
                      size: 18,
                    ),
                  ),
                ),
                SvgPicture.asset(
                  'assets/images/calendar-2.svg',
                  color: task.progressPercent >= 100
                      ? Colors.red
                      : ToDoTheme.todayCalendarColor,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    task.progressPercent >= 100
                        ? DateFormat('H:m E, d MMM').format(task.due!.toUtc())
                        : DateFormat('E, d MMM').format(task.due!.toUtc()),
                    style: task.progressPercent >= 100
                        ? ToDoTheme.todayCalendarTextStyle
                            .copyWith(color: Colors.red)
                        : ToDoTheme.todayCalendarTextStyle,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Visibility(
                    visible: task.commentsManager.hasComments(),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          FlutterIcons.dot_single_ent,
                          color: Colors.grey,
                        ),
                        SvgPicture.asset(
                          'assets/images/message.svg',
                          color: Colors.white,
                          height: 18,
                          width: 18,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            '${task.commentsManager.commentsCount()}',
                            style: ToDoTheme.todayCalendarTextStyle
                                .copyWith(color: Colors.white),
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
  const _CheckWidget({
    required this.task,
  });

  final ToDoTask task;

  @override
  Widget build(BuildContext context) {
    if ((task.progressPercent < 100)) {
      return const SizedBox.shrink();
    }
    return const Icon(
      Icons.done_outlined,
      color: ToDoTheme.inactiveCheckColor,
      size: 14,
    );
  }
}
