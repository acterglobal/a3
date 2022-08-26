import 'dart:math';

import 'package:effektio/common/store/MockData.dart';
import 'package:effektio/common/store/themes/separatedThemes.dart';
import 'package:effektio/common/widget/ToDoListView.dart';
import 'package:effektio/common/widget/ToDoTaskItem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ToDoScreen extends StatefulWidget {
  const ToDoScreen({Key? key}) : super(key: key);

  @override
  State<ToDoScreen> createState() => _ToDoScreenState();
}

class _ToDoScreenState extends State<ToDoScreen> {
  int _selectedValueIndex = 0;
  List<ToDoListView>? todoList;
  List<ToDoTaskItem>? tasksList;
  List<String> buttonText = ['Mine', 'All Teams', 'Unassigned'];
  late int listCount;
  late int taskCount;
  Random random = Random();

  @override
  void initState() {
    super.initState();
    taskCount = random.nextInt(5) + 1;
    listCount = random.nextInt(10) + 3;
    tasksList = List.generate(
      taskCount,
      (index) => ToDoTaskItem(
        title: titleTasks[random.nextInt(titleTasks.length)],
        isCompleted: random.nextBool(),
        hasMessage: random.nextBool(),
        dateTime: taskDue[random.nextInt(taskDue.length)],
      ),
    );
    todoList = List.generate(
      listCount,
      (index) => ToDoListView(
        title: titleTasks[random.nextInt(titleTasks.length)],
        subtitle: loremPara2,
        inProgress: tasksList!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: ToDoTheme.floatingABColor,
        onPressed: () {
          Navigator.pushNamed(context, '/addTodo');
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
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back),
                      color: ToDoTheme.primaryTextColor,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {},
                      icon: SvgPicture.asset('assets/images/notification.svg'),
                      color: ToDoTheme.primaryTextColor,
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 12, top: 10),
                  child: Text('Todo List', style: ToDoTheme.titleTextStyle),
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
                    children: List.generate(
                      buttonText.length,
                      (index) => radioButton(
                        text: buttonText[index],
                        index: index,
                      ),
                    ),
                  ),
                ),
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: todoList!.length,
                  itemBuilder: (context, index) => todoList![index],
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
        if (_selectedValueIndex != index) {
          setState(() {
            _selectedValueIndex = index;
            taskCount = random.nextInt(5) + 1;
            tasksList = List.generate(
              taskCount,
              (index) => ToDoTaskItem(
                title: titleTasks[random.nextInt(titleTasks.length)],
                hasMessage: random.nextBool(),
                dateTime: taskDue[random.nextInt(taskDue.length)],
                isCompleted: random.nextBool(),
              ),
            );
            listCount = random.nextInt(10) + 3;
            todoList = List.generate(
              listCount,
              (index) => ToDoListView(
                title: titleTasks[random.nextInt(titleTasks.length)],
                subtitle: loremPara2,
                inProgress: tasksList!,
              ),
            );
          });
        }
      },
      child: Container(
        height: 35,
        width: 75,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: index == _selectedValueIndex
              ? ToDoTheme.primaryColor
              : ToDoTheme.secondaryColor,
          border: Border.all(color: ToDoTheme.btnBorderColor, width: 1),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: index == _selectedValueIndex
                  ? ToDoTheme.primaryTextColor
                  : ToDoTheme.inactiveTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textScaleFactor: 0.8,
          ),
        ),
      ),
    );
  }
}
