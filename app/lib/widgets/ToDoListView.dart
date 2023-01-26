import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/todo_controller.dart';
import 'package:effektio/models/Team.dart';
import 'package:effektio/models/ToDoList.dart';
import 'package:effektio/models/ToDoTask.dart';
import 'package:effektio/screens/HomeScreens/todo/screens/CommentsScreen.dart';
import 'package:effektio/widgets/AddTaskDialog.dart';
import 'package:effektio/widgets/ExpandableText.dart';
import 'package:effektio/widgets/ToDoTaskView.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';
import 'package:get/get.dart';

class ToDoListView extends StatelessWidget {
  const ToDoListView({Key? key, required this.controller}) : super(key: key);
  final ToDoController controller;
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => controller.todos.isEmpty
          ? const Center(
              heightFactor: 10,
              child: Text(
                'You do not have any todos!',
                style: ToDoTheme.titleTextStyle,
              ),
            )
          : ListView.builder(
              itemCount: controller.todos.length,
              shrinkWrap: true,
              itemBuilder: (BuildContext context, int index) {
                return GetBuilder<ToDoController>(
                  id: 'list-item-$index',
                  builder: (_) {
                    return TodoCard(
                      controller: controller,
                      index: index,
                      isExpanded: controller.cardExpand,
                      expandBtn: controller.expandBtn,
                    );
                  },
                );
              },
            ),
    );
  }
}

class TodoCard extends StatelessWidget {
  const TodoCard({
    super.key,
    required this.controller,
    required this.index,
    required this.isExpanded,
    required this.expandBtn,
  });
  final int index;
  final bool isExpanded;
  final bool expandBtn;
  final ToDoController controller;
  @override
  Widget build(BuildContext context) {
    return Card(
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
              controller.todos[index].name,
              controller.todos[index].team,
            ),
            buildDescription(controller.todos[index].description),
            buildDivider(),
            buildComments(context),
            buildDivider(),
            buildTasksRatio(controller.todos[index]),
            buildTasksSection(
              context,
              controller.todos[index],
              isExpanded: isExpanded,
              expandBtn: expandBtn,
            )
          ],
        ),
      ),
    );
  }

  Widget buildHeaderContent(String title, Team? team) {
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
          team != null
              ? Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: const BoxDecoration(
                    color: AppCommonTheme.secondaryColor,
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  ),
                  child: Text(
                    team.name!,
                    style: ToDoTheme.listTagTextStyle,
                  ),
                )
              : const SizedBox(),
        ],
      ),
    );
  }

  Widget buildDescription(String? description) {
    return SizedBox(
      child: (description != null || description!.isNotEmpty)
          ? description.length > 80
              ? ExpandableText(description)
              : Text(description, style: ToDoTheme.descriptionTextStyle)
          : const SizedBox.shrink(),
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
          '${controller.getCompletedTasks(todo)}/${todo.tasks.length} completed',
          style: ToDoTheme.listSubtitleTextStyle.copyWith(
            color: ToDoTheme.calendarColor,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => controller.toggleCardExpand(index, isExpanded),
          icon: Icon(
            isExpanded
                ? FlutterIcons.ios_arrow_up_ion
                : FlutterIcons.ios_arrow_down_ion,
          ),
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

  Widget buildTasksSection(
    BuildContext context,
    ToDoList todo, {
    required isExpanded,
    required expandBtn,
  }) {
    List<ToDoTask> _pendingTasks =
        todo.tasks.where((element) => element.progressPercent < 100).toList();
    List<ToDoTask> _completedTasks =
        todo.tasks.where((element) => element.progressPercent >= 100).toList();
    return Visibility(
      visible: isExpanded,
      child: Column(
        children: <Widget>[
          ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(
              _pendingTasks.length,
              (index) => ToDoTaskView(
                task: _pendingTasks[index],
                controller: controller,
                todoList: todo,
              ),
            ),
          ),
          Row(
            children: <Widget>[
              ElevatedButton(
                onPressed: () => controller.toggleExpandBtn(index, expandBtn),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                    ToDoTheme.secondaryCardColor,
                  ),
                  shape: MaterialStateProperty.all<OutlinedBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Completed (${controller.getCompletedTasks(todo)})',
                      style: ToDoTheme.buttonTextStyle.copyWith(
                        color: ToDoTheme.floatingABColor,
                      ),
                      softWrap: false,
                    ),
                    Icon(
                      expandBtn
                          ? Icons.expand_more
                          : Icons.keyboard_arrow_right,
                      size: 14,
                      color: ToDoTheme.floatingABColor,
                    ),
                  ],
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
                      return FractionallySizedBox(
                        child: Material(
                          type: MaterialType.transparency,
                          child: AddTaskDialogBox(
                            toDoList: todo,
                            controller: controller,
                          ),
                        ),
                      );
                    },
                  );
                },
                child: const Text('+ Add Task'),
              ),
            ],
          ),
          Visibility(
            visible: expandBtn,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(
                  _completedTasks.length,
                  (index) => ToDoTaskView(
                    task: _completedTasks[index],
                    controller: controller,
                    todoList: todo,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
