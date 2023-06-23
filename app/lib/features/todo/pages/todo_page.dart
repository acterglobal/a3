import 'package:acter/features/todo/pages/create_todo_page.dart';
import 'package:acter/features/todo/pages/todo_mine_page.dart';
import 'package:acter/features/todo/controllers/todo_controller.dart';
import 'package:acter/features/todo/widgets/todo_list_view.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Client;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// FIXME: temporary wrapper from riverpod -> GetX client
class TodoPage extends ConsumerWidget {
  const TodoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(clientProvider)!;
    return ToDoPageX(client: client);
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
  List<String> buttonText = ['All', 'Mine', 'Unassigned', 'All Teams'];
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Padding(
          padding: EdgeInsets.only(top: 25),
          child: Text('Todo'),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(
              top: 25,
              right: 8,
            ),
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CreateTodoPage(controller: todoController),
                ),
              ),
              child: const Icon(
                Atlas.plus_circle,
                color: Colors.white,
              ),
            ),
          )
        ],
      ),
      body: _BodyWidget(
        todoController: todoController,
        buttonText: buttonText,
        buttonWidgets: buttonWidgets,
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
