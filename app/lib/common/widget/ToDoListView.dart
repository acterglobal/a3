import 'dart:math';

import 'package:effektio/common/store/themes/separatedThemes.dart';
import 'package:effektio/common/widget/ToDoTaskItem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ToDoListView extends StatefulWidget {
  const ToDoListView({
    Key? key,
    required this.title,
    required this.tasks,
    required this.subtitle,
  }) : super(key: key);
  final String title;
  final String subtitle;
  final List<ToDoTaskItem> tasks;

  @override
  State<ToDoListView> createState() => _ToDoListViewState();
}

class _ToDoListViewState extends State<ToDoListView> {
  bool initialExpand = false;
  bool expandBtn = false;
  final int likeCount = Random().nextInt(100);
  final int messageCount = Random().nextInt(100);
  List<ToDoTaskItem> completedTasks = [];
  List<ToDoTaskItem> pendingTasks = [];
  @override
  void initState() {
    super.initState();
    _sortTasks();
  }

  void _sortTasks() {
    for (var t in widget.tasks) {
      if (t.isCompleted) {
        completedTasks.add(t);
      } else {
        pendingTasks.add(t);
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      color: ToDoTheme.secondaryColor,
      child: Column(
        children: [
          ExpansionTile(
            title: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
              child: Text(widget.title, style: ToDoTheme.listTitleTextStyle),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  initialExpand
                      ? SizedBox(
                          child: Text(
                            widget.subtitle,
                            style: ToDoTheme.listSubtitleTextStyle
                                .copyWith(color: ToDoTheme.calendarColor),
                          ),
                        )
                      : SizedBox(
                          height: 40,
                          child: Text(
                            widget.subtitle,
                            style: ToDoTheme.listSubtitleTextStyle
                                .copyWith(color: ToDoTheme.calendarColor),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                  !initialExpand
                      ? const Divider(
                          color: ToDoTheme.listDividerColor,
                          indent: 0,
                          endIndent: 0,
                          thickness: 1,
                        )
                      : const SizedBox(),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        SvgPicture.asset(
                          'assets/images/heart.svg',
                          color: ToDoTheme.primaryTextColor,
                          height: 12.61,
                          width: 14.17,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Text(
                            '$likeCount',
                            style: ToDoTheme.calendarTextStyle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        SvgPicture.asset(
                          'assets/images/message.svg',
                          height: 12,
                          width: 12,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Text(
                            '$messageCount',
                            style: ToDoTheme.calendarTextStyle,
                          ),
                        ),
                        const Spacer(),
                        SvgPicture.asset(
                          'assets/images/bookmark.svg',
                          height: 12,
                          width: 12,
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    height: 20,
                    thickness: 1,
                    color: ToDoTheme.listDividerColor,
                    indent: 0,
                    endIndent: 0,
                  ),
                  Text(
                    'Active Tasks: ${pendingTasks.length}',
                    style: ToDoTheme.activeTasksTextStyle,
                  ),
                ],
              ),
            ),
            onExpansionChanged: (val) => setState(() {
              initialExpand = val;
            }),
            initiallyExpanded: false,
            trailing: const SizedBox(),
            children: [
              ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: pendingTasks,
              ),
              Row(
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.only(left: 15),
                    height: 30,
                    width: 109,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          expandBtn = !expandBtn;
                        });
                      },
                      style: ButtonStyle(
                        foregroundColor: MaterialStateProperty.all<Color>(
                          ToDoTheme.floatingABColor,
                        ),
                        backgroundColor: MaterialStateProperty.all<Color>(
                          ToDoTheme.secondaryCardColor,
                        ),
                        padding: MaterialStateProperty.all<EdgeInsets>(
                          const EdgeInsets.only(left: 8),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Text(
                            'Completed (${completedTasks.length})',
                            style: ToDoTheme.buttonTextStyle,
                            softWrap: false,
                          ),
                          Expanded(
                            child: Icon(
                              expandBtn
                                  ? Icons.expand_more
                                  : Icons.keyboard_arrow_right,
                              size: 14,
                              color: ToDoTheme.floatingABColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: TextButton(
                      style: ButtonStyle(
                        foregroundColor: MaterialStateProperty.all<Color>(
                          ToDoTheme.secondaryTextColor,
                        ),
                        textStyle: MaterialStateProperty.all<TextStyle>(
                          ToDoTheme.buttonTextStyle,
                        ),
                      ),
                      onPressed: () {},
                      child: const Text(
                        '+ Add Task',
                      ),
                    ),
                  ),
                ],
              ),
              expandBtn
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: completedTasks,
                      ),
                    )
                  : const SizedBox(),
            ],
          ),
        ],
      ),
    );
  }
}
