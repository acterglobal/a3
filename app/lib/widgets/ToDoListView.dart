import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/todo_controller.dart';
import 'package:effektio/models/ToDoList.dart';
import 'package:effektio/screens/HomeScreens/todo/screens/CommentsScreen.dart';
import 'package:effektio/widgets/AddTaskDialog.dart';
import 'package:effektio/widgets/ExpandableText.dart';
import 'package:effektio/widgets/ToDoTaskView.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';

class ToDoListView extends StatelessWidget {
  const ToDoListView({Key? key, required this.controller}) : super(key: key);
  final ToDoController controller;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ToDoList>>(
      future: controller.getTodoList(),
      builder: (BuildContext context, AsyncSnapshot<List<ToDoList>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else {
          if (snapshot.hasData) {
            if (snapshot.data!.isEmpty) {
              return Center(
                heightFactor: MediaQuery.of(context).size.height * 0.02,
                child: const Text(
                  'You do not have any todos yet',
                  style: ToDoTheme.titleTextStyle,
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              itemCount: snapshot.data!.length,
              itemBuilder: (BuildContext context, int index) {
                return InkWell(
                  onTap: () => controller.toggleCardExpand(),
                  child: Card(
                    elevation: 0,
                    margin: const EdgeInsets.all(8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    color: ToDoTheme.secondaryColor,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 15.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          buildHeaderContent(
                            snapshot.data![index].name,
                            snapshot.data![index].tags,
                          ),
                          buildDescription(snapshot.data![index].description),
                          buildDivider(),
                          buildComments(context),
                          buildDivider(),
                          buildTasksRatio(snapshot.data![index]),
                          buildTasksSection(
                            context,
                            snapshot.data![index],
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Could not load lists due to ${snapshot.error}',
                style: ToDoTheme.taskListTextStyle,
              ),
            );
          }
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget buildHeaderContent(String title, List<String>? tags) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      child: Row(
        children: [
          Flexible(
            child: Text(
              title,
              style: ToDoTheme.listTitleTextStyle,
            ),
          ),
          const SizedBox(
            width: 8.0,
          ),
          Wrap(
            direction: Axis.horizontal,
            spacing: 8.0,
            children: List.generate(
              tags!.length,
              (index) => Container(
                padding: const EdgeInsets.all(8.0),
                decoration: const BoxDecoration(
                  color: AppCommonTheme.secondaryColor,
                  borderRadius: BorderRadius.all(Radius.circular(10.0)),
                ),
                child: Text(
                  tags[index],
                  style: ToDoTheme.listTagTextStyle,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget buildDescription(String? description) {
    return SizedBox(
      child: (description != null || description!.isNotEmpty)
          ? const SizedBox.shrink()
          : description.length > 80
              ? ExpandableText(description)
              : Text(description, style: ToDoTheme.descriptionTextStyle),
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

  Widget buildTasksRatio(ToDoList todo) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        const Text(
          'Task: ',
          style: ToDoTheme.listSubtitleTextStyle,
        ),
        Text(
          '${todo.pendingTasks}/${todo.completedTasks + todo.pendingTasks} completed',
          style: ToDoTheme.listSubtitleTextStyle.copyWith(
            color: ToDoTheme.calendarColor,
          ),
        ),
        const Spacer(),
        const Icon(
          FlutterIcons.ios_arrow_down_ion,
          color: ToDoTheme.primaryTextColor,
        ),
      ],
    );
  }

  Widget buildComments(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(
              FlutterIcons.heart_evi,
              color: ToDoTheme.primaryTextColor,
            ),
            // Text(
            //   '${todoController.likeCount}',
            //   style: ToDoTheme.calendarTextStyle,
            // ),
            const SizedBox(
              width: 8,
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ToDoCommentScreen(),
                  ),
                );
              },
              child: Row(
                children: const [
                  Icon(
                    FlutterIcons.comment_evi,
                    color: ToDoTheme.primaryTextColor,
                  ),
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 5),
                  //   child: Text(
                  //     '${todoController.messageCount}',
                  //     style: ToDoTheme.calendarTextStyle,
                  //   ),
                  // ),
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
    );
  }

  Widget buildTasksSection(BuildContext context, ToDoList todo) {
    return Visibility(
      visible: controller.cardExpand.value,
      child: Column(
        children: <Widget>[
          ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(
              todo.tasks.length,
              (index) => ToDoTaskView(task: todo.tasks[index]),
            ),
          ),
          Row(
            children: <Widget>[
              SizedBox(
                height: 30,
                width: 109,
                child: ElevatedButton(
                  onPressed: () => controller.expandBtn,
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
                        'Completed ${todo.completedTasks}',
                        style: ToDoTheme.buttonTextStyle,
                        softWrap: false,
                      ),
                      Expanded(
                        child: Icon(
                          controller.expandBtn.value
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
          // if (controller.expandBtn.value)
          //   Padding(
          //     padding: const EdgeInsets.symmetric(vertical: 10),
          //     child: ListView(
          //       shrinkWrap: true,
          //       physics: const NeverScrollableScrollPhysics(),
          //       children: List.generate(todo.completedTasks, (index) {
          //         todo.tasks.
          //       }),
          //     ),
          //   ),
        ],
      ),
    );
  }
}
