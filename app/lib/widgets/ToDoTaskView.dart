import 'dart:math';
import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/models/ToDoTask.dart';
// import 'package:effektio/screens/HomeScreens/todo/ToDoTaskEditor.dart';
// import 'package:effektio/widgets/CompletedTaskCard.dart';
// import 'package:effektio/widgets/IncompleteTaskCard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ToDoTaskView extends StatelessWidget {
  final ToDoTask task;

  const ToDoTaskView({Key? key, required this.task}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => ToDoTaskEditor(
        //       task: task,
        //     ),
        //   ),
        // );
      },
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
    final deviceWidth = MediaQuery.of(context).size.width;
    return Card(
      elevation: 0,
      color: deviceWidth < 600
          ? ToDoTheme.secondaryCardColor
          : AppCommonTheme.transparentColor,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildCardHeader(deviceWidth),
          _buildCardContent(), //small screens
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

  Widget _buildCardHeader(double deviceWidth) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: () {
              // if (widget.toggleCompletion(widget)) {
              //   ScaffoldMessenger.of(context).clearSnackBars();
              //   ScaffoldMessenger.of(context).showSnackBar(
              //     SnackBar(
              //       content: Text(
              //         "You've checked off '${widget.task.name}'",
              //       ),
              //       action: SnackBarAction(
              //         label: 'Undo',
              //         onPressed: () {
              //           showNotYetImplementedMsg(
              //             context,
              //             'Undo of tasks is not yet implemented',
              //           );
              //         },
              //       ),
              //       duration: const Duration(milliseconds: 2000),
              //       backgroundColor: AppCommonTheme.primaryColor,
              //       behavior: SnackBarBehavior.floating,
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(5.0),
              //       ),
              //     ),
              //   );
              // } else {
              //   ScaffoldMessenger.of(context).clearSnackBars();
              //   ScaffoldMessenger.of(context).showSnackBar(
              //     SnackBar(
              //       content: Text(
              //         "You've reopened '${widget.title}'",
              //       ),
              //       duration: const Duration(milliseconds: 2000),
              //       backgroundColor:
              //       AppCommonTheme.secondaryColor,
              //       behavior: SnackBarBehavior.floating,
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(5.0),
              //       ),
              //     ),
              //   );
              // }
            },
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
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 3),
              child: Text(
                widget.task.name,
                style: ToDoTheme.taskTitleTextStyle.copyWith(
                  decoration:
                      widget.task.isDone ? TextDecoration.lineThrough : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // large screens
          if (deviceWidth > 600) ...[
            Padding(
              padding: const EdgeInsets.only(left: 40, right: 8),
              child: SvgPicture.asset(
                'assets/images/calendar-2.svg',
                // color: isAllDay
                //     ? ToDoTheme.todayCalendarColor
                //     : ToDoTheme.calendarColor,
              ),
            ),
            Text(
              widget.task.due.toString(),
              // style: isAllDay
              //     ? ToDoTheme.todayCalendarTextStyle
              //     : ToDoTheme.calendarTextStyle,
            ),
            const SizedBox(
              width: 40,
            ),
            // widget.hasMessage
            //     ? Row(
            //         children: [
            //           SvgPicture.asset(
            //             'assets/images/message.svg',
            //             height: 12,
            //             width: 12,
            //           ),
            //           Padding(
            //             padding: const EdgeInsets.only(left: 5),
            //             child: Text(
            //               '$widget.messageCount',
            //               style: ToDoTheme.buttonTextStyle.copyWith(
            //                 color: ToDoTheme.primaryTextColor,
            //               ),
            //             ),
            //           ),
            //         ],
            //       )
            //     : const SizedBox(),
            const SizedBox(
              width: 25,
            ),
            // Flexible(
            //   child: SizedBox(
            //     width: 110,
            //     child: AvatarStack(
            //       borderWidth: 0,
            //       settings: settings,
            //       avatars: widget.avatars,
            //       infoWidgetBuilder: avatarBuilder,
            //       width: 24,
            //       height: 24,
            //     ),
            //   ),
            // ),
          ]
        ],
      ),
    );
  }

  Widget _buildCardContent() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SvgPicture.asset(
                'assets/images/calendar-2.svg',
                // color: isAllDay
                //     ? ToDoTheme.todayCalendarColor
                //     : ToDoTheme.calendarColor,
              ),
            ),
          ),
          Expanded(
            flex: 7,
            child: Text(
              widget.task.due.toString(),
              // style: isAllDay
              //     ? ToDoTheme.todayCalendarTextStyle
              //     : ToDoTheme.calendarTextStyle,
            ),
          ),
          // widget.hasMessage
          //     ? Expanded(
          //         flex: 2,
          //         child: Row(
          //           children: [
          //             SvgPicture.asset(
          //               'assets/images/message.svg',
          //               height: 12,
          //               width: 12,
          //             ),
          //             Padding(
          //               padding: const EdgeInsets.only(left: 5),
          //               child: Text(
          //                 '$messageCount',
          //                 style: ToDoTheme.buttonTextStyle.copyWith(
          //                   color: ToDoTheme.primaryTextColor,
          //                 ),
          //               ),
          //             ),
          //           ],
          //         ),
          //       )
          //     : const Spacer(flex: 2),
          // Expanded(
          //   flex: 7,
          //   child: Padding(
          //     padding: const EdgeInsets.all(15),
          //     child: AvatarStack(
          //       borderWidth: 0,
          //       settings: settings,
          //       avatars: widget.avatars,
          //       infoWidgetBuilder: avatarBuilder,
          //       width: 28,
          //       height: 28,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
