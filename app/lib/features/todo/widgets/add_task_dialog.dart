import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/todo/controllers/todo_controller.dart';
import 'package:acter/models/ToDoList.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AddTaskDialog extends StatefulWidget {
  final ToDoList toDoList;

  const AddTaskDialog({
    Key? key,
    required this.toDoList,
  }) : super(key: key);

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogBoxState();
}

class _AddTaskDialogBoxState extends State<AddTaskDialog> {
  DateTime? _selectedDate;
  int idx = 0;

  void setSelectedDate(DateTime? time) {
    if (mounted) {
      setState(() => _selectedDate = time);
    }
  }

  void setBtnIndex(int index) {
    if (mounted) {
      setState(() => idx = index);
    }
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
                decoration: const BoxDecoration(),
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
  final ToDoList list;
  final DateTime? selectedDate;

  const _InputWidget(this.selectedDate, {required this.list});

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
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: TextField(
                      controller: titleInputController,
                      onChanged: handleInputChange,
                      style: Theme.of(context).textTheme.bodySmall,
                      cursorColor: Theme.of(context).colorScheme.tertiary,
                      // focusNode: todoController.addTaskNode,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'What is the title of task?',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: handleTaskCreate,
                icon: Icon(
                  Atlas.paper_airplane,
                  color: titleInputController.text.isEmpty
                      ? Theme.of(context).colorScheme.neutral4
                      : Theme.of(context).colorScheme.tertiary,
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  void handleInputChange(String value) {
    if (mounted) {
      setState(() {
        titleInputController.text = value;
        // prevent setting cursor position
        titleInputController.selection = TextSelection.fromPosition(
          TextPosition(offset: titleInputController.text.length),
        );
      });
    }
  }

  Future<void> handleTaskCreate() async {
    if (titleInputController.text.isNotEmpty) {
      var eventId = await controller.createToDoTask(
        name: titleInputController.text,
        dueDate: widget.selectedDate,
        list: widget.list,
      );
      debugPrint('TASK CREATED: $eventId');
    }
  }
}

class _ScheduleBtnWidget extends StatefulWidget {
  final String text;
  final int buttonIndex;
  final int index;
  final void Function(int) updateIndex;
  final void Function(DateTime?) updateSelected;

  const _ScheduleBtnWidget({
    required this.text,
    required this.buttonIndex,
    required this.index,
    required this.updateIndex,
    required this.updateSelected,
  });

  @override
  State<_ScheduleBtnWidget> createState() => __ScheduleBtnWidgetState();
}

class __ScheduleBtnWidgetState extends State<_ScheduleBtnWidget> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final now = DateTime.now();
        if (mounted) {
          setState(() {
            widget.updateIndex(widget.buttonIndex);
            if (widget.buttonIndex == 1) {
              widget.updateSelected(now);
            } else if (widget.buttonIndex == 2) {
              widget.updateSelected(DateTime(now.year, now.month, now.day + 1));
            } else if (widget.buttonIndex == 3) {
              Future.delayed(
                const Duration(seconds: 0),
                () => handleDatePicker(context),
              );
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 16,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const Icon(
              Atlas.calendar_dots,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              widget.text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium,
            )
          ],
        ),
      ),
    );
  }

  void handleClick() {
    final now = DateTime.now();
    if (mounted) {
      setState(() {
        widget.updateIndex(widget.buttonIndex);
        if (widget.buttonIndex == 1) {
          widget.updateSelected(now);
        } else if (widget.buttonIndex == 2) {
          widget.updateSelected(DateTime(now.year, now.month, now.day + 1));
        } else if (widget.buttonIndex == 3) {
          Future.delayed(
            const Duration(seconds: 0),
            () => handleDatePicker(context),
          );
        }
      });
    }
  }

  Future<void> handleDatePicker(BuildContext ctx) async {
    DateTime? pickedDate = await showDatePicker(
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
          data: ThemeData.dark().copyWith(),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      if (mounted) {
        setState(() => widget.updateSelected(pickedDate));
      }
    } else {
      if (mounted) {
        setState(() {
          widget.updateSelected(null);
          widget.updateIndex(0);
        });
      }
    }
  }
}
