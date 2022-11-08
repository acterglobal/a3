import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/todo_controller.dart';
import 'package:effektio/widgets/ToDoTaskItem.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ToDoListView extends StatefulWidget {
  final String title;
  final String subtitle;
  final int idx;

  const ToDoListView({
    Key? key,
    required this.idx,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

  @override
  State<ToDoListView> createState() => _ToDoListViewState();
}

class _ToDoListViewState extends State<ToDoListView> {
  ToDoController todoController = ToDoController.instance;
  late List<ToDoTaskItem> completedTasks;
  late List<ToDoTaskItem> pendingTasks;

  @override
  void initState() {
    super.initState();
    completedTasks =
        todoController.tasks[widget.idx].where((w) => w.isCompleted).toList();
    pendingTasks =
        todoController.tasks[widget.idx].where((w) => !w.isCompleted).toList();

    todoController.tasks[widget.idx].listen(
      (p0) => setState(() {
        completedTasks = todoController.tasks[widget.idx]
            .where((w) => w.isCompleted)
            .toList();
        pendingTasks = todoController.tasks[widget.idx]
            .where((w) => !w.isCompleted)
            .toList();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
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
                buildSubtitle(),
                if (!todoController.initialExpand.value) buildDivider(),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Icon(
                        FlutterIcons.tasks_faw5s,
                        color: ToDoTheme.primaryTextColor,
                        size: 20.0,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Text(
                          '${pendingTasks.length}',
                          style: ToDoTheme.calendarTextStyle,
                        ),
                      ),
                      const Icon(
                        FlutterIcons.check_evi,
                        color: ToDoTheme.primaryTextColor,
                        size: 20.0,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Text(
                          '${completedTasks.length}',
                          style: ToDoTheme.calendarTextStyle,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        FlutterIcons.heart_evi,
                        color: ToDoTheme.primaryTextColor,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Text(
                          '${todoController.likeCount}',
                          style: ToDoTheme.calendarTextStyle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        FlutterIcons.comment_evi,
                        color: ToDoTheme.primaryTextColor,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Text(
                          '${todoController.messageCount}',
                          style: ToDoTheme.calendarTextStyle,
                        ),
                      ),
                      const Icon(
                        FlutterIcons.bookmark_outline_mco,
                        color: ToDoTheme.primaryTextColor,
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
              ],
            ),
          ),
          onExpansionChanged: (val) => todoController.toggleExpand(),
          initiallyExpanded: true,
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
                          'Completed (${completedTasks.length})',
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
                    child: const Text('+ Add Task'),
                  ),
                ),
              ],
            ),
            if (todoController.expandBtn.value)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: completedTasks,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildSubtitle() {
    if (todoController.initialExpand.value) {
      return SizedBox(
        child: Text(
          widget.subtitle,
          style: ToDoTheme.listSubtitleTextStyle.copyWith(
            color: ToDoTheme.calendarColor,
          ),
        ),
      );
    }
    return SizedBox(
      height: 40,
      child: Text(
        widget.subtitle,
        style: ToDoTheme.listSubtitleTextStyle.copyWith(
          color: ToDoTheme.calendarColor,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget buildDivider() {
    return const Divider(
      color: ToDoTheme.listDividerColor,
      indent: 0,
      endIndent: 0,
      thickness: 1,
    );
  }
}
