import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/widgets/default_page_header.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/todo/pages/todo_mine_page.dart';
import 'package:acter/features/todo/controllers/todo_controller.dart';
import 'package:acter/features/todo/widgets/todo_list_view.dart';
import 'package:acter/features/todo/widgets/task_list_card.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:acter/features/todo/providers/tasklists.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// FIXME: temporary wrapper from riverpod -> GetX client
class TodoPage extends ConsumerWidget {
  const TodoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskLists = ref.watch(tasksListsProvider);
    // return ToDoPageX(client: client);
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          PageHeaderWidget(
            title: 'Tasks',
            sectionColor: Theme.of(context).colorScheme.tasksBG,
            actions: [
              IconButton(
                icon: const Icon(Atlas.funnel_sort_thin),
                onPressed: () {
                  customMsgSnackbar(
                    context,
                    'Task filters not yet implemented',
                  );
                },
              ),
              IconButton(
                icon: const Icon(Atlas.plus_circle),
                onPressed: () {
                  customMsgSnackbar(
                    context,
                    'TaskList Creation page not yet implemented',
                  );
                },
              ),
            ],
            expandedContent: const Text(
              'ToDo Lists and Tasks of all your spaces can be found here',
            ),
          ),
          taskLists.when(
            data: (taskLists) {
              if (taskLists.isEmpty) {
                return SliverToBoxAdapter(
                  child: SizedBox(
                    height: 450,
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            'Congrats!',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Icon(
                              Atlas.check_circle_thin,
                              size: 50.0,
                              color: Theme.of(context).colorScheme.success,
                            ),
                          ),
                          Text(
                            'you are done with all your tasks!',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'see open tasks',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    TaskList taskList = taskLists[index];
                    return TaskListCard(taskList: taskList);
                  },
                  childCount: taskLists.length,
                ),
              );
            },
            error: (error, stack) => SliverToBoxAdapter(
              child: SizedBox(
                height: 450,
                child: Center(
                  child: Text('Loading tasks failed: $error'),
                ),
              ),
            ),
            loading: () => const SliverToBoxAdapter(
              child: SizedBox(
                height: 450,
                child: Center(
                  child: Text('Loading'),
                ),
              ),
            ),
          )
          // Padding(
          //   padding: const EdgeInsets.only(
          //     top: 25,
          //     right: 8,
          //   ),
          //   child: InkWell(
          //     onTap: () => Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) =>
          //             CreateTodoPage(controller: todoController),
          //       ),
          //     ),
          //     child: const Icon(
          //       Atlas.plus_circle,
          //       color: Colors.white,
          //     ),
          //   ),

          // SliverToBoxAdapter(
          //   child: _BodyWidget(
          //     todoController: todoController,
          //     buttonText: buttonText,
          //     buttonWidgets: buttonWidgets,
          //   ),
          // ),
        ],
      ),
    );
  }
}

class ToDoPageX extends StatefulWidget {
  const ToDoPageX({Key? key, required this.client}) : super(key: key);
  final Client client;
  @override
  State<ToDoPageX> createState() => _ToDoPageXState();
}

class _ToDoPageXState extends State<ToDoPageX> {
  late final ToDoController todoController;
  late final List<Widget> buttonWidgets;

  @override
  void initState() {
    super.initState();
    todoController = Get.put(ToDoController(client: widget.client));
    buttonWidgets = [
      ToDoListView(controller: todoController),
      const ToDoMinePage(),
      const Placeholder(),
      const Placeholder()
    ];
  }

  @override
  void dispose() {
    Get.delete<ToDoController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          PageHeaderWidget(
            title: 'Tasks',
            sectionColor: Colors.pink.shade600,
            actions: [
              IconButton(
                icon: const Icon(Atlas.funnel_sort_thin),
                onPressed: () {
                  customMsgSnackbar(
                    context,
                    'Task filters not yet implemented',
                  );
                },
              ),
              IconButton(
                icon: const Icon(Atlas.plus_circle),
                onPressed: () {
                  customMsgSnackbar(
                    context,
                    'TaskList Creation page not yet implemented',
                  );
                },
              ),
            ],
            expandedContent: const Text(
              'ToDo Lists and Tasks of all your spaces can be found here',
            ),
          ),
          // Padding(
          //   padding: const EdgeInsets.only(
          //     top: 25,
          //     right: 8,
          //   ),
          //   child: InkWell(
          //     onTap: () => Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) =>
          //             CreateTodoPage(controller: todoController),
          //       ),
          //     ),
          //     child: const Icon(
          //       Atlas.plus_circle,
          //       color: Colors.white,
          //     ),
          //   ),

          // SliverToBoxAdapter(
          //   child: _BodyWidget(
          //     todoController: todoController,
          //     buttonText: buttonText,
          //     buttonWidgets: buttonWidgets,
          //   ),
          // ),
        ],
      ),
    );
  }
}

class _BodyWidget extends StatelessWidget {
  const _BodyWidget({
    required this.todoController,
    required this.buttonText,
    required this.buttonWidgets,
  });

  final ToDoController todoController;
  final List<String> buttonText;
  final List<Widget> buttonWidgets;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Obx(
            () => Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Row(
                    children: <Widget>[
                      _RadioBtn(
                        todoController: todoController,
                        text: buttonText[0],
                        index: 0,
                      ),
                      _RadioBtn(
                        todoController: todoController,
                        text: buttonText[1],
                        index: 1,
                      ),
                      _RadioBtn(
                        todoController: todoController,
                        text: buttonText[2],
                        index: 2,
                      ),
                      const Spacer(),
                      _RadioBtn(
                        todoController: todoController,
                        text: buttonText[3],
                        index: 3,
                      ),
                    ],
                  ),
                  Expanded(
                    child:
                        buttonWidgets[todoController.selectedValueIndex.value],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadioBtn extends StatelessWidget {
  const _RadioBtn({
    required this.todoController,
    required this.text,
    required this.index,
  });

  final ToDoController todoController;
  final String text;
  final int index;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        todoController.updateButtonIndex(index);
      },
      hoverColor: Colors.transparent,
      child: Container(
        height: 35,
        width: 75,
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelMedium,
            textScaleFactor: 0.8,
          ),
        ),
      ),
    );
  }
}
