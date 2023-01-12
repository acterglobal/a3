import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/todo_controller.dart';
import 'package:effektio/widgets/OnboardingWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';
import 'package:get/get.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({Key? key, required this.controller})
      : super(key: key);
  final ToDoController controller;

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ToDoTheme.backgroundGradient2Color,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: ToDoTheme.toDoDecoration,
          height: MediaQuery.of(context).size.height -
              MediaQuery.of(context).size.height * 0.12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Text(
                  'Create Task',
                  style: ToDoTheme.titleTextStyle,
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                height: 60,
                decoration: BoxDecoration(
                  color: ToDoTheme.textFieldColor,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: const Color(0x18E5E5E5), width: 0.5),
                ),
                child: TextFormField(
                  controller: nameController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(10, 12, 10, 0),
                    border: InputBorder.none,
                    hintText: 'Task Title',
                    // hide default counter helper
                    counterText: '',
                    // pass the hint text parameter here
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  maxLength: 30,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Cannot be empty';
                    }
                    return null;
                  },
                  onChanged: (value) =>
                      widget.controller.updateWordCount(value.length),
                ),
              ),
              Obx(
                () => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 16, 0),
                  child: Text(
                    'Word Count: ${widget.controller.taskNameCount.value}',
                    style: ToDoTheme.textFieldCounterStyle,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                decoration: BoxDecoration(
                  color: ToDoTheme.textFieldColor,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: const Color(0x18E5E5E5), width: 0.5),
                ),
                child: TextFormField(
                  controller: descriptionController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(10, 12, 10, 0),
                    border: InputBorder.none,
                    hintText: 'Task Description',
                    // pass the hint text parameter here
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  maxLines: 5,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: AppCommonTheme.textFieldColor,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: const Text(
                        'Select Team',
                        style: TextStyle(color: ToDoTheme.calendarColor),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: Transform.rotate(
                        angle: 45,
                        child: const Icon(
                          FlutterIcons.flow_branch_ent,
                          color: ToDoTheme.calendarColor,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const Spacer(),
              Obx(
                () => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: CustomOnbaordingButton(
                    onPressed: widget.controller.taskNameCount < 30
                        ? () async {
                            await widget.controller
                                .createToDoList(
                                  nameController.text,
                                  descriptionController.text,
                                )
                                .then(
                                  (value) => debugPrint('TASK Created :$value'),
                                );
                            Navigator.pop(context);
                          }
                        : null,
                    title: 'Create Task',
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
