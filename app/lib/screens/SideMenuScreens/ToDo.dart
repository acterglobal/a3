import 'package:effektio/common/store/MockData.dart';
import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/todo_controller.dart';
import 'package:effektio/widgets/AppCommon.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ToDoScreen extends StatefulWidget {
  const ToDoScreen({Key? key}) : super(key: key);

  @override
  State<ToDoScreen> createState() => _ToDoScreenState();
}

class _ToDoScreenState extends State<ToDoScreen> {
  final ToDoController todoController = ToDoController.instance;
  List<String> buttonText = ['Mine', 'All Teams', 'Unassigned'];

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
      extendBodyBehindAppBar: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: ToDoTheme.floatingABColor,
        onPressed: () {
          showNotYetImplementedMsg(
            context,
            'Add Task-List Action not yet implemented',
          );
        },
        child: const Icon(Icons.add_outlined, size: 25),
      ),
      body: Container(
        decoration: ToDoTheme.toDoDecoration,
        child: Padding(
          padding: const EdgeInsets.only(top: 25),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Text('Tasks', style: ToDoTheme.titleTextStyle),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 12, top: 10),
                  child: Text(loremPara1, style: ToDoTheme.subtitleTextStyle),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 15),
                  child: Wrap(
                    direction: Axis.horizontal,
                    spacing: 5.0,
                    children: List.generate(buttonText.length, (int index) {
                      return radioButton(text: buttonText[index], index: index);
                    }),
                  ),
                ),
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: todoController.todoList!.length,
                  itemBuilder: (BuildContext context, int index) {
                    return todoController.todoList![index];
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget radioButton({required String text, required int index}) {
    return InkWell(
      splashColor: ToDoTheme.primaryTextColor,
      onTap: () {
        todoController.updateIndex(index);
        showNotYetImplementedMsg(context, 'Task filters not yet implemented');
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
                  fontSize: 12,
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
