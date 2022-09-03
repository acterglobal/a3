import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:effektio/common/store/themes/separatedThemes.dart';

class AddToDoScreen extends StatefulWidget {
  const AddToDoScreen({Key? key}) : super(key: key);

  @override
  State<AddToDoScreen> createState() => _AddToDoScreenState();
}

class _AddToDoScreenState extends State<AddToDoScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: ToDoTheme.floatingABColor,
        onPressed: () {},
        child: const Icon(Icons.add_outlined, size: 25),
      ),
      body: Container(
        decoration: ToDoTheme.toDoDecoration,
        child: Padding(
          padding: const EdgeInsets.only(top: 25),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                    color: ToDoTheme.primaryTextColor,
                  ),
                  const Text('Todo List', style: ToDoTheme.titleTextStyle),
                  IconButton(
                    onPressed: () {},
                    icon: SvgPicture.asset('assets/images/notification.svg'),
                    color: ToDoTheme.primaryTextColor,
                  ),
                ],
              ),
              Column(
                children: <Widget>[
                  ListTile(
                    leading: SvgPicture.asset(
                      'assets/images/calendar-2.svg',
                      width: 20,
                      height: 20,
                      color: ToDoTheme.primaryTextColor,
                    ),
                    title: const Text(
                      'My Day',
                      style: ToDoTheme.taskListTextStyle,
                    ),
                    minLeadingWidth: 20,
                  ),
                  ListTile(
                    leading: SvgPicture.asset(
                      'assets/images/subscribed.svg',
                      width: 20,
                      height: 20,
                      color: ToDoTheme.subscribedIconColor,
                    ),
                    title: const Text(
                      'Subscribed',
                      style: ToDoTheme.taskListTextStyle,
                    ),
                    minLeadingWidth: 20,
                  ),
                  ListTile(
                    leading: SvgPicture.asset(
                      'assets/images/profile-tick.svg',
                      width: 20,
                      height: 20,
                      color: ToDoTheme.assignedIconColor,
                    ),
                    title: const Text(
                      'Assigned to me',
                      style: ToDoTheme.taskListTextStyle,
                    ),
                    minLeadingWidth: 20,
                  ),
                  ListTile(
                    leading: SvgPicture.asset(
                      'assets/images/calendar-tick.svg',
                      width: 20,
                      height: 20,
                      color: ToDoTheme.plannedIconColor,
                    ),
                    title: const Text(
                      'Planned',
                      style: ToDoTheme.taskListTextStyle,
                    ),
                    minLeadingWidth: 20,
                  ),
                  ListTile(
                    leading: SvgPicture.asset(
                      'assets/images/tasks-icon.svg',
                      width: 20,
                      height: 20,
                      color: ToDoTheme.taskIconColor,
                    ),
                    title: const Text(
                      'Tasks',
                      style: ToDoTheme.taskListTextStyle,
                    ),
                    minLeadingWidth: 20,
                  ),
                  ListTile(
                    leading: SvgPicture.asset(
                      'assets/images/profile-delete.svg',
                      width: 20,
                      height: 20,
                      color: ToDoTheme.unAssignedIconColor,
                    ),
                    title: const Text(
                      'Unassigned',
                      style: ToDoTheme.taskListTextStyle,
                    ),
                    minLeadingWidth: 20,
                  ),
                ],
              ),
              const Divider(
                color: ToDoTheme.dividerColor,
                indent: 15,
                endIndent: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
