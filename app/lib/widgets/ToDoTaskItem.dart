import 'dart:math';

import 'package:avatar_stack/avatar_stack.dart';
import 'package:avatar_stack/positions.dart';
import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/screens/SideMenuScreens/ToDoTaskEditor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:effektio/widgets/AppCommon.dart';

class ToDoTaskItem extends StatefulWidget {
  final String title;
  final bool hasMessage;
  final bool isCompleted;
  final Function toggleCompletion;
  final String dateTime;
  final String subtitle;
  final String? notes;
  final DateTime? lastUpdated;

  const ToDoTaskItem({
    Key? key,
    required this.title,
    this.isCompleted = false,
    this.hasMessage = false,
    required this.toggleCompletion,
    required this.dateTime,
    required this.subtitle,
    required this.notes,
    required this.lastUpdated,
  }) : super(key: key);

  @override
  State<ToDoTaskItem> createState() => _ToDoTaskItemState();
}

class _ToDoTaskItemState extends State<ToDoTaskItem> {
  bool isAllDay = false;
  late List<ImageProvider<Object>> avatars;
  final int countPeople = Random().nextInt(10);
  final int messageCount = Random().nextInt(100);
  int id = Random().nextInt(70);
  final settings = RestrictedAmountPositions(
    maxAmountItems: 5,
    maxCoverage: 0.7,
    minCoverage: 0.1,
    align: StackAlign.right,
  );

  @override
  void initState() {
    super.initState();

    avatars = getMockAvatars(countPeople);
    if (widget.dateTime.contains('All Day')) {
      isAllDay = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ToDoTaskEditor(
              item: widget,
              avatars: avatars,
            ),
          ),
        );
      },
      child: Card(
        elevation: 0,
        color: ToDoTheme.secondaryCardColor,
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 2),
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () {
                      if (widget.toggleCompletion(widget)) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "You've checked off '${widget.title}'",
                            ),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () {
                                showNotYetImplementedMsg(
                                  context,
                                  'Undo of tasks is not yet implemented',
                                );
                              },
                            ),
                            duration: const Duration(milliseconds: 2000),
                            backgroundColor: AppCommonTheme.primaryColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "You've reopened '${widget.title}'",
                            ),
                            duration: const Duration(milliseconds: 2000),
                            backgroundColor: AppCommonTheme.secondaryColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                        );
                      }
                    },
                    child: CircleAvatar(
                      backgroundColor: AppCommonTheme.transparentColor,
                      radius: 18,
                      child: Container(
                        height: 25,
                        width: 25,
                        decoration: BoxDecoration(
                          color: widget.isCompleted
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
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, top: 3),
                      child: Text(
                        widget.title,
                        style: ToDoTheme.taskTitleTextStyle.copyWith(
                          decoration: widget.isCompleted
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
                                  '$messageCount',
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
                        avatars: avatars,
                        infoWidgetBuilder: avatarBuilder,
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
      ),
    );
  }

  Widget avatarBuilder(int count) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: ToDoTheme.infoAvatarColor,
      child: Text('+$count', style: ToDoTheme.infoAvatarTextStyle),
    );
  }

  Widget? checkBuilder() {
    if (!widget.isCompleted) {
      return null;
    }
    return const Icon(
      Icons.done_outlined,
      color: ToDoTheme.inactiveCheckColor,
      size: 10,
    );
  }

  List<ImageProvider<Object>> getMockAvatars(int count) {
    return List.generate(count, (index) {
      int id = Random().nextInt(70);
      return NetworkImage('https://i.pravatar.cc/100?img = ${id.toString()}');
    });
  }
}
