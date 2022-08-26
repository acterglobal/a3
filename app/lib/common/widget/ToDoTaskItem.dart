import 'dart:math';

import 'package:avatar_stack/avatar_stack.dart';
import 'package:avatar_stack/positions.dart';
import 'package:effektio/common/store/themes/separatedThemes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ToDoTaskItem extends StatefulWidget {
  const ToDoTaskItem({
    Key? key,
    required this.title,
    this.isCompleted = false,
    this.hasMessage = false,
    required this.dateTime,
  }) : super(key: key);
  final String title;
  final bool hasMessage;
  final bool isCompleted;
  final String dateTime;
  @override
  State<ToDoTaskItem> createState() => _ToDoTaskItemState();
}

class _ToDoTaskItemState extends State<ToDoTaskItem> {
  bool checkStatus = false;
  bool isAllDay = false;
  late List<ImageProvider<Object>> _avatars;
  Random random = Random();
  late int countPeople;
  int id = 0;
  final settings = RestrictedAmountPositions(
    maxAmountItems: 5,
    maxCoverage: 0.7,
    minCoverage: 0.1,
    align: StackAlign.right,
  );
  @override
  void initState() {
    super.initState();
    countPeople = random.nextInt(10);
    _avatars = _getMockAvatars(countPeople);
    checkStatus = widget.isCompleted;
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
      color: ToDoTheme.secondaryCardColor,
      margin: const EdgeInsets.fromLTRB(22, 5, 48, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 2),
            child: Row(
              children: <Widget>[
                GestureDetector(
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
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, top: 3),
                    child: Text(
                      widget.title,
                      style: ToDoTheme.taskTitleTextStyle.copyWith(
                        decoration:
                            checkStatus ? TextDecoration.lineThrough : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
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
                  flex: 7,
                  child: Text(
                    widget.dateTime,
                    style: isAllDay
                        ? ToDoTheme.todayCalendarTextStyle
                        : ToDoTheme.calendarTextStyle,
                  ),
                ),
                widget.hasMessage
                    ? Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/images/message.svg',
                              height: 12,
                              width: 12,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 5),
                              child: Text(
                                '${random.nextInt(20) + 1}',
                                style: ToDoTheme.buttonTextStyle.copyWith(
                                  color: ToDoTheme.primaryTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const Spacer(flex: 2),
                Expanded(
                  flex: 7,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: AvatarStack(
                      borderWidth: 0,
                      settings: settings,
                      avatars: _avatars,
                      infoWidgetBuilder: _infoAvatar,
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

  Widget _infoAvatar(int count) => CircleAvatar(
        radius: 28,
        backgroundColor: ToDoTheme.infoAvatarColor,
        child: Text('+$count', style: ToDoTheme.infoAvatarTextStyle),
      );

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
