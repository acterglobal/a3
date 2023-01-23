import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/todo_controller.dart';
import 'package:effektio/models/ToDoList.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:intl/intl.dart';

class AddTaskDialogBox extends StatefulWidget {
  const AddTaskDialogBox({
    Key? key,
    required this.toDoList,
    required this.controller,
  }) : super(key: key);
  final ToDoList toDoList;
  final ToDoController controller;

  @override
  State<AddTaskDialogBox> createState() => _AddTaskDialogBoxState();
}

class _AddTaskDialogBoxState extends State<AddTaskDialogBox> {
  final titleInputController = TextEditingController();

  DateTime _selectedDate = DateTime.now().toUtc();
  int idx = 0;

  @override
  Widget build(BuildContext context) {
    return KeyboardVisibilityBuilder(
      builder: (context, isKeyboardVisible) {
        return Align(
          alignment:
              isKeyboardVisible ? Alignment.center : Alignment.bottomCenter,
          child: Wrap(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  color: ToDoTheme.backgroundGradientColor,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        _buildScheduleBtn(
                          ctx: context,
                          text: 'Today',
                          index: 0,
                        ),
                        _buildScheduleBtn(
                          ctx: context,
                          text: 'Tomorrow',
                          index: 1,
                        ),
                        _buildScheduleBtn(
                          ctx: context,
                          text: (idx > 1)
                              ? DateFormat('EEEE, d MMM, yyyy')
                                  .format(_selectedDate)
                              : 'Pick a Day',
                          index: 2,
                        )
                      ],
                    ),
                    _buildInput(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: 80,
                  decoration: BoxDecoration(
                    color: ToDoTheme.secondaryColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: TextField(
                      controller: titleInputController,
                      onChanged: (val) {
                        setState(() {
                          titleInputController.text = val;
                          //prevent setting cursor position
                          titleInputController.selection =
                              TextSelection.fromPosition(
                            TextPosition(
                              offset: titleInputController.text.length,
                            ),
                          );
                        });
                      },
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.grey,
                      // focusNode: todoController.addTaskNode,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'What is the title of task?',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: (titleInputController.text.isEmpty)
                    ? null
                    : () async {
                        await widget.controller
                            .createToDoTask(
                              name: titleInputController.text,
                              dueDate: _selectedDate,
                              list: widget.toDoList,
                            )
                            .then((res) => debugPrint('TASK CREATED: $res'));
                        Navigator.pop(context);
                      },
                icon: Icon(
                  FlutterIcons.send_fea,
                  color: titleInputController.text.isEmpty
                      ? Colors.grey
                      : Colors.pink,
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleBtn({
    required BuildContext ctx,
    required String text,
    required int index,
  }) {
    return InkWell(
      onTap: () {
        final now = DateTime.now();
        setState(() {
          idx = index;
          if (index == 0) {
            _selectedDate = now;
          } else if (index == 1) {
            _selectedDate = DateTime(now.year, now.month, now.day + 1);
          } else {
            Future.delayed(
              const Duration(seconds: 0),
              () => _showDatePicker(ctx),
            );
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 16,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: idx == index
              ? ToDoTheme.floatingABColor
              : ToDoTheme.secondaryColor,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Icon(
              FlutterIcons.calendar_weekend_outline_mco,
              color: idx == index
                  ? ToDoTheme.primaryTextColor
                  : ToDoTheme.calendarColor,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              text,
              textAlign: TextAlign.center,
              style: idx == index
                  ? ToDoTheme.calendarTextStyle.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: ToDoTheme.primaryTextColor,
                    )
                  : ToDoTheme.calendarTextStyle.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
            )
          ],
        ),
      ),
    );
  }

  void _showDatePicker(BuildContext ctx) async {
    await showDatePicker(
      context: ctx,
      initialDatePickerMode: DatePickerMode.day,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      currentDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 10),
      confirmText: 'Done',
      cancelText: 'Cancel',
      builder: (BuildContext ctx, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            dialogBackgroundColor: ToDoTheme.bottomSheetColor,
            colorScheme: ColorScheme.fromSwatch().copyWith(
              primary: ToDoTheme.primaryColor,
              onSurface: ToDoTheme.primaryTextColor,
            ),
          ),
          child: child!,
        );
      },
    ).then((_pickedDate) {
      if (_pickedDate != null) {
        setState(() {
          _selectedDate = _pickedDate;
        });
      } else {
        setState(() {
          _selectedDate = DateTime.now();
          idx = 0;
        });
      }
    });
  }
}
