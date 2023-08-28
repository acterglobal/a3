import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/todo/controllers/todo_controller.dart';
import 'package:acter/features/todo/widgets/add_task_dialog.dart';
import 'package:acter/features/todo/widgets/todo_task_view.dart';
import 'package:acter/models/Team.dart';
import 'package:acter/models/ToDoList.dart';
import 'package:acter/models/ToDoTask.dart';
import 'package:acter/common/widgets/expandable_text.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TodoCard extends StatelessWidget {
  const TodoCard({
    super.key,
    required this.controller,
    required this.index,
    required this.isExpanded,
    required this.expandBtn,
  });
  final ToDoController controller;
  final int index;
  final bool isExpanded;
  final bool expandBtn;
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 8.0,
          horizontal: 15.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _HeaderWidget(
              title: controller.todos[index].name,
              team: controller.todos[index].team,
            ),
            _DescriptionWidget(
              description: controller.todos[index].description,
            ),
            const _DividerWidget(),
            _CommentsWidget(context: context),
            const _DividerWidget(),
            _TasksRatioWidget(
              controller: controller,
              index: index,
              isExpanded: isExpanded,
              todo: controller.todos[index],
            ),
            Obx(
              () => _TasksWidget(
                controller: controller,
                index: index,
                context: context,
                todo: controller.todos[index],
                isExpanded: isExpanded,
                expandBtn: expandBtn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TasksWidget extends StatelessWidget {
  const _TasksWidget({
    required this.controller,
    required this.index,
    required this.context,
    required this.todo,
    required this.isExpanded,
    required this.expandBtn,
  });
  final ToDoController controller;
  final int index;
  final BuildContext context;
  final ToDoList todo;
  final bool isExpanded;
  final bool expandBtn;

  @override
  Widget build(BuildContext context) {
    List<ToDoTask> pendingTasks =
        todo.tasks.where((element) => element.progressPercent < 100).toList();
    List<ToDoTask> completedTasks =
        todo.tasks.where((element) => element.progressPercent >= 100).toList();
    return Visibility(
      visible: isExpanded,
      child: Column(
        children: <Widget>[
          ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(
              pendingTasks.length,
              (index) => ToDoTaskView(
                task: pendingTasks[index],
                todoList: todo,
              ),
            ),
          ),
          Row(
            children: <Widget>[
              InkWell(
                onTap: () => controller.toggleExpandBtn(index, expandBtn),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Completed (${controller.getCompletedTasks(todo)})',
                      softWrap: false,
                      style: Theme.of(context).textTheme.labelMedium!,
                    ),
                    Icon(
                      expandBtn
                          ? Icons.expand_more
                          : Icons.keyboard_arrow_right,
                      size: 14,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) {
                      return FractionallySizedBox(
                        child: Material(
                          type: MaterialType.transparency,
                          child: AddTaskDialog(
                            toDoList: todo,
                          ),
                        ),
                      );
                    },
                  );
                },
                child: Text(
                  '+ Add Task',
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: Theme.of(context).colorScheme.tertiary2,
                      ),
                ),
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
                  completedTasks.length,
                  (index) => ToDoTaskView(
                    task: completedTasks[index],
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

class _TasksRatioWidget extends StatelessWidget {
  const _TasksRatioWidget({
    required this.controller,
    required this.index,
    required this.isExpanded,
    required this.todo,
  });
  final ToDoController controller;
  final int index;
  final bool isExpanded;
  final ToDoList todo;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          'Task: ',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        Text(
          '${controller.getCompletedTasks(todo)}/${todo.tasks.length} completed',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const Spacer(),
        IconButton(
          onPressed: () => controller.toggleCardExpand(index, isExpanded),
          icon: Icon(
            isExpanded ? Atlas.arrow_up_circle : Atlas.arrow_down_circle,
          ),
        ),
      ],
    );
  }
}

class _CommentsWidget extends StatelessWidget {
  const _CommentsWidget({
    required this.context,
  });

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const Icon(
          Atlas.heart,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: InkWell(
            onTap: () {},
            child: const Icon(Atlas.chat_dots),
          ),
        ),
        const Spacer(),
        const Icon(
          Atlas.book,
        ),
      ],
    );
  }
}

class _DescriptionWidget extends StatelessWidget {
  const _DescriptionWidget({
    required this.description,
  });

  final String? description;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: (description != null || description!.isNotEmpty)
          ? description!.length > 80
              ? ExpandableText(description!)
              : Text(
                  description!,
                  style: Theme.of(context).textTheme.bodySmall,
                )
          : const SizedBox.shrink(),
    );
  }
}

class _DividerWidget extends StatelessWidget {
  const _DividerWidget();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      indent: 0,
      endIndent: 0,
      thickness: 1,
    );
  }
}

class _HeaderWidget extends StatelessWidget {
  const _HeaderWidget({
    required this.title,
    required this.team,
  });

  final String title;
  final Team? team;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(
            width: 8.0,
          ),
          team != null
              ? Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary2,
                    borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                  ),
                  child: Text(
                    team!.name!,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
