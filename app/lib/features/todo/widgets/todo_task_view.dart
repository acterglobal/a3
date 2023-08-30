import 'package:acter/features/todo/controllers/todo_controller.dart';
import 'package:acter/features/todo/widgets/task_card.dart';
import 'package:acter/models/ToDoList.dart';
import 'package:acter/models/ToDoTask.dart';
import 'package:acter/features/todo/pages/task_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ToDoTaskView extends StatefulWidget {
  final ToDoTask task;
  final ToDoList todoList;
  const ToDoTaskView({
    Key? key,
    required this.task,
    required this.todoList,
  }) : super(key: key);

  @override
  State<ToDoTaskView> createState() => _ToDoTaskViewState();
}

class _ToDoTaskViewState extends State<ToDoTaskView> {
  final ToDoController controller = Get.find<ToDoController>();
  late int idx;
  late int listIdx;
  @override
  void initState() {
    super.initState();
    listIdx = controller.todos.indexOf(widget.todoList);
    idx = widget.todoList.tasks.indexOf(widget.task);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailPage(
              index: idx,
              listIndex: listIdx,
            ),
          ),
        );
      },
      child: TaskCard(
        controller: controller,
        task: widget.task,
        todoList: widget.todoList,
      ),
    );
  }
}
