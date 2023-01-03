import 'dart:math';

import 'package:avatar_stack/positions.dart';
import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/widgets/AppCommon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';

class CompletedTaskCard extends StatefulWidget {
  final String title;
  final bool isCompleted;
  final String dateTime;
  final Function toggleCompletion;
  final bool hasMessage;
  final List<ImageProvider<Object>> avatars;

  const CompletedTaskCard({Key? key, required this.title, required this.isCompleted, required this.dateTime, required this.toggleCompletion, required this.hasMessage, required this.avatars,}) : super(key: key);

  @override
  State<CompletedTaskCard> createState() => _CompletedTaskCardState();
}

class _CompletedTaskCardState extends State<CompletedTaskCard> {

  bool isAllDay = false;
  final int messageCount = Random().nextInt(100);
  final settings = RestrictedAmountPositions(
    maxAmountItems: 5,
    maxCoverage: 0.7,
    minCoverage: 0.1,
    align: StackAlign.right,
  );

  @override
  void initState() {
    super.initState();

    if (widget.dateTime.contains('All Day')) {
      isAllDay = true;
    }
  }
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
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
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
                          backgroundColor:
                          AppCommonTheme.secondaryColor,
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
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, top: 3),
                    child: Text(
                      widget.title,
                      style: ToDoTheme.taskTitleTextStyle.copyWith(
                        decoration: TextDecoration.lineThrough,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              right: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    FlutterIcons.check_circle_outline_mco,
                    color: AppCommonTheme.primaryColor,
                    size: 16,
                  ),
                ),
                Text(
                  widget.dateTime,
                  style: ToDoTheme.completeCalendarTextStyle,
                ),
              ],
            ),
          ),
        ],
      ),
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

  Widget avatarBuilder(int count) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: ToDoTheme.infoAvatarColor,
      child: Text('+$count', style: ToDoTheme.infoAvatarTextStyle),
    );
  }

  List<ImageProvider<Object>> getMockAvatars(int count) {
    return List.generate(count, (index) {
      int id = Random().nextInt(70);
      return NetworkImage('https://i.pravatar.cc/100?img = ${id.toString()}');
    });
  }
}
