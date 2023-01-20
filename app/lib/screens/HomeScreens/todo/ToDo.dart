import 'package:beamer/beamer.dart';
import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/todo_controller.dart';
import 'package:effektio/screens/HomeScreens/todo/ToDoMine.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ToDoScreen extends StatefulWidget {
  const ToDoScreen({Key? key}) : super(key: key);

  @override
  State<ToDoScreen> createState() => _ToDoScreenState();
}

class _ToDoScreenState extends State<ToDoScreen> {
  final ToDoController todoController = ToDoController.instance;
  List<String> buttonText = ['All', 'Mine', 'Unassigned', 'space', 'All Teams'];

  @override
  void initState() {
    super.initState();
    todoController.init();
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
        backgroundColor: ToDoTheme.backgroundGradient2Color,
        title:
        const Text('Todo List', style: ToDoTheme.titleTextStyle),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: InkWell(
              onTap: () {
                Beamer.of(context).beamToNamed('/createTask');
              },
              child: const Icon(
                Icons.add,
                color: Colors.white,
              ),
            ),
          )
        ],
      ),
      body: Container(
        decoration: ToDoTheme.toDoDecoration,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Wrap(
                      direction: Axis.horizontal,
                      spacing: 5.0,
                      children:
                      List.generate(buttonText.length, (int index) {
                        return index == 3
                            ? const SizedBox(
                          width: 48,
                        )
                            : radioButton(
                          text: buttonText[index],
                          index: index,
                        );
                      }),
                    ),
                  ),
                  GetBuilder<ToDoController>(
                    id: 'radiobtn',
                    builder: (ToDoController controller) {
                      return Container(
                        child: todoController.selectedValueIndex == 0
                            ? Expanded(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount:
                            todoController.todoList!.length,
                            itemBuilder: (
                                BuildContext context,
                                int index,
                                ) {
                              return todoController
                                  .todoList![index];
                            },
                          ),
                        )
                            : todoController.selectedValueIndex == 1
                            ? const ToDoMineScreen()
                            : todoController.selectedValueIndex == 2
                            ? const Placeholder()
                            : const Placeholder(),
                      );
                    },
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget radioButton({required String text, required int index}) {
    return InkWell(
      splashColor: ToDoTheme.primaryTextColor,
      onTap: () {
        todoController.updateIndex(index);
      },
      child: GetBuilder<ToDoController>(
        id: 'radiobtn',
        builder: (ToDoController controller) {
          return Container(
            height: 35,
            width: 75,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: index == controller.selectedValueIndex
                  ? ToDoTheme.primaryColor
                  : ToDoTheme.secondaryColor,
              border: Border.all(color: ToDoTheme.btnBorderColor, width: 1),
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: index == controller.selectedValueIndex
                      ? ToDoTheme.primaryTextColor
                      : ToDoTheme.inactiveTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textScaleFactor: 0.8,
              ),
            ),
          );
        },
      ),
    );
  }
}
