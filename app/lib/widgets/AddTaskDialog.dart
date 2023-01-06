import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/todo_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class AddTaskDialogBox extends StatefulWidget {

  const AddTaskDialogBox({Key? key}) : super(key: key);

  @override
  State<AddTaskDialogBox> createState() => _AddTaskDialogBoxState();
}

class _AddTaskDialogBoxState extends State<AddTaskDialogBox> {
  ToDoController todoController = ToDoController.instance;

  @override
  Widget build(BuildContext context) {
    return KeyboardVisibilityBuilder(
      builder: (context, isKeyboardVisible) {
        return Align(
          alignment: isKeyboardVisible ? Alignment.center : Alignment.bottomCenter,
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
                      children: [
                        Container(
                          padding : const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration : BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: ToDoTheme.secondaryColor,
                          ),
                          child: Row(
                            children: [
                              const Icon(FlutterIcons.calendar_weekend_outline_mco, color: ToDoTheme.calendarColor, size: 16,),
                              const SizedBox(width: 4,),
                              Text('Today', style: ToDoTheme.calendarTextStyle.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),)
                            ],
                          ),
                        ),
                        Container(
                          padding : const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration : BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: ToDoTheme.secondaryColor,
                          ),
                          child: Row(
                            children: [
                              const Icon(FlutterIcons.calendar_weekend_outline_mco, color: ToDoTheme.calendarColor, size: 16,),
                              const SizedBox(width: 4,),
                              Text('Tomorrow', style: ToDoTheme.calendarTextStyle.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),)
                            ],
                          ),
                        ),
                        Container(
                          padding : const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration : BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: ToDoTheme.secondaryColor,
                          ),
                          child: Row(
                            children: [
                              const Icon(FlutterIcons.calendar_weekend_outline_mco, color: ToDoTheme.calendarColor, size: 16,),
                              const SizedBox(width: 4,),
                              Text('Pick a day', style: ToDoTheme.calendarTextStyle.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),)
                            ],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
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
                                      style: const TextStyle(color: Colors.white),
                                      cursorColor: Colors.grey,
                                      focusNode: todoController.addTaskNode,
                                      autofocus: true,
                                      decoration: const InputDecoration(
                                        hintText: 'Add a comment',
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
                                onPressed: () {
                                  const snackBar = SnackBar(
                                    content: Text('Send icon tapped'),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                                },
                                icon: const Icon(FlutterIcons.send_fea, color: Colors.pink),
                              )
                            ],
                          ),
                        ],
                      ),
                    )
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
