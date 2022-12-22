import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';

class ToDoMineScreen extends StatefulWidget {
  const ToDoMineScreen({Key? key}) : super(key: key);

  @override
  State<ToDoMineScreen> createState() => _ToDoMineScreenState();
}

class _ToDoMineScreenState extends State<ToDoMineScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        ListTile(
          leading: Icon(
            FlutterIcons.check_circle_faw,
            color: Colors.white,
          ),
          title: Text(
            'My assignments',
            style: ToDoTheme.taskTitleTextStyle,
          ),
        ),
        ListTile(
          leading: Icon(
            FlutterIcons.bookmark_mdi,
            color: Colors.white,
          ),
          title: Text(
            'Bookmarks',
            style: ToDoTheme.taskTitleTextStyle,
          ),
        ),
        ListTile(
          leading: Icon(
            FlutterIcons.pie_chart_ent,
            color: Colors.white,
          ),
          title: Text(
            'My recent activity',
            style: ToDoTheme.taskTitleTextStyle,
          ),
        ),
        ListTile(
          leading: Icon(
            FlutterIcons.event_mdi,
            color: Colors.white,
          ),
          title: Text(
            'Upcoming event',
            style: ToDoTheme.taskTitleTextStyle,
          ),
        ),
      ],
    );
  }
}
