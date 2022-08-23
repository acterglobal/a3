import 'dart:math';

import 'package:effektio/common/store/MockData.dart';
import 'package:effektio/common/store/themes/separatedThemes.dart';
import 'package:effektio/common/widget/TaskItem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ToDoScreen extends StatefulWidget {
  const ToDoScreen({Key? key}) : super(key: key);

  @override
  State<ToDoScreen> createState() => _ToDoScreenState();
}

class _ToDoScreenState extends State<ToDoScreen> {
  int _selectedValueIndex = 0;
  List<String> buttonText = ['Mine', 'Subscribed', 'Unassigned'];
  late int countTasks;
  Random random = Random();
  @override
  void initState() {
    super.initState();
    countTasks = random.nextInt(10) + 3;
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
                  child: Text(loremPara, style: ToDoTheme.subtitleTextStyle),
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
                  itemCount: countTasks,
                  itemBuilder: (context, index) {
                    return TaskItem(
                      title: titleTasks[random.nextInt(titleTasks.length)],
                      subtitle:
                          subtitleTasks[random.nextInt(subtitleTasks.length)],
                      dateTime: taskDue[random.nextInt(taskDue.length)],
                    );
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
        setState(() {
          _selectedValueIndex = index;
        });
      },
      child: Container(
        height: 35,
        width: 75,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: index == _selectedValueIndex
              ? ToDoTheme.primaryColor
              : ToDoTheme.secondaryColor,
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
