import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/todo_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class ToDoListView extends StatefulWidget {
  const ToDoListView({
    Key? key,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

  final String title;
  final String subtitle;

  @override
  State<ToDoListView> createState() => _ToDoListViewState();
}

class _ToDoListViewState extends State<ToDoListView> {
  ToDoController todoController = ToDoController.instance;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      color: ToDoTheme.secondaryColor,
      child: Obx(
        () => ExpansionTile(
          title: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
            child: Text(widget.title, style: ToDoTheme.listTitleTextStyle),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                todoController.initialExpand.value
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
                !todoController.initialExpand.value
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
                          '${todoController.likeCount}',
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
                          '${todoController.messageCount}',
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
                  'Active Tasks: ${todoController.pendingTasks.length}',
                  style: ToDoTheme.activeTasksTextStyle,
                ),
              ],
            ),
          ),
          onExpansionChanged: (val) => todoController.toggleExpand(),
          initiallyExpanded: false,
          trailing: const SizedBox(),
          children: [
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: todoController.pendingTasks,
            ),
            Row(
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.only(left: 15),
                  height: 30,
                  width: 109,
                  child: ElevatedButton(
                    onPressed: () {
                      todoController.toggleExpandBtn();
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
                          'Completed (${todoController.completedTasks.length})',
                          style: ToDoTheme.buttonTextStyle,
                          softWrap: false,
                        ),
                        Expanded(
                          child: Icon(
                            todoController.expandBtn.value
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
            todoController.expandBtn.value
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: todoController.completedTasks,
                    ),
                  )
                : const SizedBox(),
          ],
        ),
      ),
    );
  }
}
