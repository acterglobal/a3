import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/widgets/OnboardingWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';

class CreateTaskScreen extends StatelessWidget {
  const CreateTaskScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ToDoTheme.backgroundGradient2Color,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
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
                      color: AppCommonTheme.textFieldColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.fromLTRB(10, 12, 10, 0),
                        border: InputBorder.none,
                        hintText: 'Task Title',
                        // pass the hint text parameter here
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      style: const TextStyle(color: Colors.white),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Cannot be empty';
                        }
                        return null;
                      },
                      onChanged: (value) {},
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    decoration: BoxDecoration(
                      color: AppCommonTheme.textFieldColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.fromLTRB(10, 12, 10, 0),
                        border: InputBorder.none,
                        hintText: 'Task Description',
                        // pass the hint text parameter here
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      style: const TextStyle(color: Colors.white),
                      maxLines: 5,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Cannot be empty';
                        }
                        return null;
                      },
                      onChanged: (value) {},
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
                  )
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: CustomOnbaordingButton(
                  onPressed: () {},
                  title: 'Create Task',
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
