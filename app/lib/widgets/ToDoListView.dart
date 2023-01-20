import 'package:beamer/beamer.dart';
import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/todo_controller.dart';
import 'package:effektio/widgets/AddTaskDialog.dart';
import 'package:effektio/widgets/ExpandableText.dart';
import 'package:effektio/widgets/ToDoTaskItem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';
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
    return GestureDetector(
      onTap: () {
        todoController.toggleExpand();
      },
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.all(8.0),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        color: ToDoTheme.secondaryColor,
        child: Obx(
          () => Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.title,
                          style: ToDoTheme.listTitleTextStyle,
                        ),
                      ),
                      const SizedBox(
                        width: 8.0,
                      ),
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: const BoxDecoration(
                          color: AppCommonTheme.secondaryColor,
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                        ),
                        child: const Text(
                          'Design',
                          style: ToDoTheme.listTagTextStyle,
                        ),
                      )
                    ],
                  ),
                ),
                buildSubtitle(),
                buildDivider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          FlutterIcons.heart_evi,
                          color: ToDoTheme.primaryTextColor,
                        ),
                        Text(
                          '${todoController.likeCount}',
                          style: ToDoTheme.calendarTextStyle,
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        InkWell(
                          onTap: () {
                            Beamer.of(context).beamToNamed('/todoComment');
                          },
                          child: Row(
                            children: [
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
                            ],
                          ),
                        )
                      ],
                    ),
                    const Icon(
                      FlutterIcons.bookmark_border_mdi,
                      color: ToDoTheme.primaryTextColor,
                    ),
                  ],
                ),
                buildDivider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Tasks: ',
                          style: ToDoTheme.listSubtitleTextStyle.copyWith(
                            color: ToDoTheme.calendarColor,
                          ),
                        ),
                        Text(
                          '${pendingTasks.length}/${completedTasks.length + pendingTasks.length} completed',
                          style: ToDoTheme.listSubtitleTextStyle.copyWith(
                            color: ToDoTheme.calendarColor,
                          ),
                        )
                      ],
                    ),
                    const Icon(
                      FlutterIcons.ios_arrow_down_ion,
                      color: ToDoTheme.primaryTextColor,
                    ),
                  ],
                ),
                Visibility(
                  visible: todoController.initialExpand.value,
                  child: Column(
                    children: [
                      ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: pendingTasks,
                      ),
                      Row(
                        children: <Widget>[
                          SizedBox(
                            height: 30,
                            width: 109,
                            child: ElevatedButton(
                              onPressed: () {
                                todoController.toggleExpandBtn();
                              },
                              style: ButtonStyle(
                                foregroundColor:
                                    MaterialStateProperty.all<Color>(
                                  ToDoTheme.floatingABColor,
                                ),
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
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
                          TextButton(
                            style: ButtonStyle(
                              foregroundColor: MaterialStateProperty.all<Color>(
                                ToDoTheme.secondaryTextColor,
                              ),
                              textStyle: MaterialStateProperty.all<TextStyle>(
                                ToDoTheme.buttonTextStyle,
                              ),
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) {
                                  return const FractionallySizedBox(
                                    child: Material(
                                      type: MaterialType.transparency,
                                      child: AddTaskDialogBox(),
                                    ),
                                  );
                                },
                              );
                            },
                            child: const Text('+ Add Task'),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSubtitle() {
    return SizedBox(
      child: widget.subtitle.length > 80
          ? ExpandableText(widget.subtitle)
          : Text(
              widget.subtitle,
              style: ToDoTheme.listSubtitleTextStyle.copyWith(
                color: ToDoTheme.calendarColor,
              ),
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
