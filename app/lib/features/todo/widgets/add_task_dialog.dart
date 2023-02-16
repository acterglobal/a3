import 'package:effektio/common/themes/seperated_themes.dart';
import 'package:effektio/features/todo/controllers/todo_controller.dart';
import 'package:effektio/models/ToDoList.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({
    Key? key,
    required this.toDoList,
  }) : super(key: key);
  final ToDoList toDoList;

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogBoxState();
}

class _AddTaskDialogBoxState extends State<AddTaskDialog> {
  DateTime? _selectedDate;
  int idx = 0;

  void setSelectedDate(DateTime? time) {
    setState(() {
      _selectedDate = time;
    });
  }

  void setBtnIndex(int index) {
    setState(() {
      idx = index;
    });
  }

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
                        _ScheduleBtnWidget(
                          text: 'Today',
                          buttonIndex: 1,
                          index: idx,
                          updateIndex: setBtnIndex,
                          updateSelected: setSelectedDate,
                        ),
                        _ScheduleBtnWidget(
                          text: 'Tomorrow',
                          buttonIndex: 2,
                          index: idx,
                          updateIndex: setBtnIndex,
                          updateSelected: setSelectedDate,
                        ),
                        _ScheduleBtnWidget(
                          text: (idx > 2 && _selectedDate != null)
                              ? DateFormat('EEEE, d MMM, yyyy')
                                  .format(_selectedDate!)
                              : 'Pick a Day',
                          buttonIndex: 3,
                          index: idx,
                          updateIndex: setBtnIndex,
                          updateSelected: setSelectedDate,
                        ),
                      ],
                    ),
                    _InputWidget(
                      _selectedDate,
                      list: widget.toDoList,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InputWidget extends StatefulWidget {
  const _InputWidget(this.selectedDate, {required this.list});
  final ToDoList list;
  final DateTime? selectedDate;
  @override
  State<_InputWidget> createState() => _InputWidgetState();
}

class _InputWidgetState extends State<_InputWidget> {
  final titleInputController = TextEditingController();
  final controller = Get.find<ToDoController>();
  @override
  Widget build(BuildContext context) {
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
                        await controller
                            .createToDoTask(
                              name: titleInputController.text,
                              dueDate: widget.selectedDate,
                              list: widget.list,
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
}

class _ScheduleBtnWidget extends StatefulWidget {
  const _ScheduleBtnWidget({
    required this.text,
    required this.buttonIndex,
    required this.index,
    required this.updateIndex,
    required this.updateSelected,
  });
  final String text;
  final int buttonIndex;
  final int index;
  final void Function(int) updateIndex;
  final void Function(DateTime?) updateSelected;
  @override
  State<_ScheduleBtnWidget> createState() => __ScheduleBtnWidgetState();
}

class __ScheduleBtnWidgetState extends State<_ScheduleBtnWidget> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final now = DateTime.now();
        setState(() {
          widget.updateIndex(widget.buttonIndex);
          if (widget.buttonIndex == 1) {
            widget.updateSelected(now);
          } else if (widget.buttonIndex == 2) {
            widget.updateSelected(DateTime(now.year, now.month, now.day + 1));
          } else if (widget.buttonIndex == 3) {
            Future.delayed(
              const Duration(seconds: 0),
              () => _showDatePicker(context),
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
          color: widget.index == widget.buttonIndex
              ? ToDoTheme.floatingABColor
              : ToDoTheme.secondaryColor,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Icon(
              FlutterIcons.calendar_weekend_outline_mco,
              color: widget.index == widget.buttonIndex
                  ? ToDoTheme.primaryTextColor
                  : ToDoTheme.calendarColor,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              widget.text,
              textAlign: TextAlign.center,
              style: widget.index == widget.buttonIndex
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
          widget.updateSelected(_pickedDate);
        });
      } else {
        setState(() {
          widget.updateSelected(null);
          widget.updateIndex(0);
        });
      }
    });
  }
}
