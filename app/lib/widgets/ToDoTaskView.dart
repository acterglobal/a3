import 'package:beamer/beamer.dart';
import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/models/ToDoTask.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class ToDoTaskView extends StatelessWidget {
  final ToDoTask task;

  const ToDoTaskView({Key? key, required this.task}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          Beamer.of(context).beamToNamed('/todoTaskEditor', data: task),
      child: TaskCard(task: task),
    );
  }
}

class TaskCard extends StatefulWidget {
  const TaskCard({super.key, required this.task});
  final ToDoTask task;
  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
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
                    onTap: () {},
                    child: CircleAvatar(
                      backgroundColor: AppCommonTheme.transparentColor,
                      radius: 18,
                      child: Container(
                        height: 25,
                        width: 25,
                        decoration: BoxDecoration(
                          color: widget.task.isDone
                              ? ToDoTheme.activeCheckColor
                              : ToDoTheme.inactiveCheckColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: 1.5,
                            color: ToDoTheme.floatingABColor,
                          ),
                        ),
                        child: checkBuilder(),
                      ),
                    ),
                  ),
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      widget.task.name,
                      style: ToDoTheme.taskTitleTextStyle.copyWith(
                        decoration: widget.task.isDone
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
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SvgPicture.asset(
                  'assets/images/calendar-2.svg',
                  color: ToDoTheme.todayCalendarColor,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    DateFormat('EEEE, d MMM').format(widget.task.due!.toUtc()),
                    style: ToDoTheme.todayCalendarTextStyle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? checkBuilder() {
    if (!widget.task.isDone) {
      return null;
    }
    return const Icon(
      Icons.done_outlined,
      color: ToDoTheme.inactiveCheckColor,
      size: 10,
    );
  }
}
