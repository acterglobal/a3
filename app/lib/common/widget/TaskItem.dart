import 'dart:math';

import 'package:avatar_stack/avatar_stack.dart';
import 'package:avatar_stack/positions.dart';
import 'package:effektio/common/store/themes/separatedThemes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TaskItem extends StatefulWidget {
  const TaskItem({
    Key? key,
    required this.title,
    required this.subtitle,
    this.isChecked = false,
    required this.dateTime,
  }) : super(key: key);
  final String title;
  final String subtitle;
  final bool isChecked;
  final String dateTime;
  @override
  State<TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem> {
  bool checkStatus = false;
  bool isAllDay = false;
  late List<ImageProvider<Object>> _avatars;
  Random random = Random();
  late int countPeople;
  int id = 0;
  final settings = RestrictedAmountPositions(
    maxAmountItems: 4,
    maxCoverage: 0.7,
    minCoverage: 0.1,
    align: StackAlign.right,
  );
  @override
  void initState() {
    super.initState();
    countPeople = random.nextInt(4) + 1;
    _avatars = _getMockAvatars(countPeople);
    checkStatus = widget.isChecked;
    if (widget.dateTime.contains('All Day')) {
      setState(() {
        isAllDay = true;
      });
    }
  }

  void _toggleCheck() {
    setState(() {
      checkStatus = !checkStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: ToDoTheme.secondaryColor,
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 2),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 8,
                  child: Text(
                    widget.title,
                    style: ToDoTheme.taskTitleTextStyle,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: () => _toggleCheck(),
                    child: Container(
                      height: 18,
                      width: 18,
                      decoration: BoxDecoration(
                        color: checkStatus
                            ? ToDoTheme.activeCheckColor
                            : ToDoTheme.inactiveCheckColor,
                        shape: BoxShape.circle,
                      ),
                      child: checkStatus
                          ? const Icon(
                              Icons.done_outlined,
                              color: ToDoTheme.inactiveCheckColor,
                              size: 10,
                            )
                          : const SizedBox(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10, top: 3),
            child: Text(
              widget.subtitle,
              style: ToDoTheme.taskSubtitleTextStyle,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SvgPicture.asset(
                      'assets/images/calendar-2.svg',
                      color: isAllDay
                          ? ToDoTheme.todayCalendarColor
                          : ToDoTheme.calendarColor,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    widget.dateTime,
                    style: isAllDay
                        ? ToDoTheme.todayCalendarTextStyle
                        : ToDoTheme.calendarTextStyle,
                  ),
                ),
                const Spacer(flex: 2),
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: AvatarStack(
                      settings: settings,
                      avatars: _avatars,
                      width: 28,
                      height: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<ImageProvider<Object>> _getMockAvatars(int count) => List.generate(
        count,
        (index) {
          id = random.nextInt(70);
          return NetworkImage(
            'https://i.pravatar.cc/100?img = ${id.toString()}',
          );
        },
      );
}
