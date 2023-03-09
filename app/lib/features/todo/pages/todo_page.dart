import 'package:effektio/common/themes/seperated_themes.dart';
import 'package:effektio/features/todo/pages/create_todo_page.dart';
import 'package:effektio/features/todo/pages/todo_mine_page.dart';
import 'package:effektio/features/todo/controllers/todo_controller.dart';
import 'package:effektio/features/todo/widgets/todo_list_view.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart' show Client;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ToDoPage extends StatefulWidget {
  const ToDoPage({Key? key, required this.client}) : super(key: key);
  final Client client;
  @override
  State<ToDoPage> createState() => _ToDoPageState();
}

class _ToDoPageState extends State<ToDoPage> {
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
        backgroundColor: ToDoTheme.backgroundGradient2Color,
        title: const Padding(
          padding: EdgeInsets.only(top: 25),
          child: Text('Todo', style: ToDoTheme.titleTextStyle),
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
                Icons.add,
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
    return Container(
      decoration: ToDoTheme.toDoDecoration,
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
      splashColor: ToDoTheme.primaryTextColor,
      onTap: () {
        todoController.updateButtonIndex(index);
      },
      child: Container(
        height: 35,
        width: 75,
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: index == todoController.selectedValueIndex.value
              ? ToDoTheme.primaryColor
              : ToDoTheme.secondaryColor,
          border: Border.all(color: ToDoTheme.btnBorderColor, width: 1),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: index == todoController.selectedValueIndex.value
                  ? ToDoTheme.primaryTextColor
                  : ToDoTheme.inactiveTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textScaleFactor: 0.8,
          ),
        ),
      ),
    );
  }
}
