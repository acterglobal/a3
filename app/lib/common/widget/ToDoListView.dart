import 'dart:math';

import 'package:effektio/common/store/themes/separatedThemes.dart';
import 'package:effektio/common/widget/ToDoTaskItem.dart';
import 'package:flutter/material.dart';

class ToDoListView extends StatefulWidget {
  const ToDoListView({
    Key? key,
    required this.title,
    required this.inProgress,
    required this.subtitle,
  }) : super(key: key);
  final String title;
  final String subtitle;
  final List<ToDoTaskItem> inProgress;

  @override
  State<ToDoListView> createState() => _ToDoListViewState();
}

class _ToDoListViewState extends State<ToDoListView> {
  Random random = Random();
  bool initialExpand = false;
  @override
  void initState() {
    super.initState();
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
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 2),
              child: initialExpand
                  ? Text(widget.title, style: ToDoTheme.listTitleTextStyle)
                  : SizedBox(
                      height: 40,
                      child: Text(
                        widget.title,
                        style: ToDoTheme.listTitleTextStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(left: 8, top: 5),
              child: Column(
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: ButtonStyle(
                        foregroundColor: MaterialStateProperty.all<Color>(
                            ToDoTheme.secondaryTextColor),
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
            ),
            onExpansionChanged: (val) => setState(() {
              initialExpand = val;
            }),
            initiallyExpanded: false,
            trailing: const SizedBox(),
            children: widget.inProgress,
          ),
        ],
      ),
    );
  }
}
