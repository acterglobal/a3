import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/todo_controller.dart';
import 'package:effektio/screens/HomeScreens/todo/screens/CommentsScreen.dart';
import 'package:effektio/widgets/ExpandableText.dart';
import 'package:effektio/widgets/ToDoTaskItem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
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
  bool isCardExpanded = false;

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
        setState(() {
          isCardExpanded = !isCardExpanded;
        });
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ToDoCommentScreen(),
                              ),
                            );
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
                  visible: isCardExpanded,
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
                              showDialogBox();
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

  showDialogBox(){

    final content = KeyboardVisibilityBuilder(
        builder: (context, isKeyboardVisible) {
          return Align(
            alignment: isKeyboardVisible ? Alignment.center : Alignment.bottomCenter,
            child: Wrap(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: const BoxDecoration(
                    color: ToDoTheme.backgroundGradientColor,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Container(
                            padding : EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            decoration : BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: ToDoTheme.secondaryColor
                            ),
                            child: Row(
                              children: [
                                Icon(FlutterIcons.calendar_weekend_outline_mco, color: ToDoTheme.calendarColor, size: 16,),
                                SizedBox(width: 4,),
                                Text('Today', style: ToDoTheme.calendarTextStyle.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500
                                ),)
                              ],
                            ),
                          ),
                          Container(
                            padding : EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            decoration : BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: ToDoTheme.secondaryColor
                            ),
                            child: Row(
                              children: [
                                Icon(FlutterIcons.calendar_weekend_outline_mco, color: ToDoTheme.calendarColor, size: 16,),
                                SizedBox(width: 4,),
                                Text('Tomorrow', style: ToDoTheme.calendarTextStyle.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500
                                ),)
                              ],
                            ),
                          ),
                          Container(
                            padding : EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            decoration : BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: ToDoTheme.secondaryColor
                            ),
                            child: Row(
                              children: [
                                Icon(FlutterIcons.calendar_weekend_outline_mco, color: ToDoTheme.calendarColor, size: 16,),
                                SizedBox(width: 4,),
                                Text('Pick a day', style: ToDoTheme.calendarTextStyle.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500
                                ),)
                              ],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Container(
                                    width: MediaQuery.of(context).size.width,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: ToDoTheme.secondaryColor,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: TextField(
                                        style: const TextStyle(color: Colors.white),
                                        cursorColor: Colors.grey,
                                        focusNode: todoController.addTaskNode,
                                        autofocus: true,
                                        decoration: const InputDecoration(
                                          hintText: 'Add a comment',
                                          hintStyle: TextStyle(
                                            color: Colors.grey,
                                          ),
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    const snackBar = SnackBar(
                                      content: Text('Send icon tapped'),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                                  },
                                  icon: const Icon(FlutterIcons.send_fea, color: Colors.pink),
                                )
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        }
    );


    showDialog(
        context: context,
        builder: (ctx) {
          return FractionallySizedBox(
            child: Material(
              type: MaterialType.transparency,
              child: content,
            ),
          );
        }
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
