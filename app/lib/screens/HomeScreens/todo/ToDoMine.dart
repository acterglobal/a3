import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/screens/HomeScreens/todo/MyAssignments.dart';
import 'package:effektio/screens/HomeScreens/todo/MyRecentActivity.dart';
import 'package:effektio/screens/HomeScreens/todo/ToDoBookmarks.dart';
import 'package:effektio/widgets/AppCommon.dart';
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
      children: [
        ListTile(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const MyAssignmentScreen(),
              ),
            );
          },
          leading: const Icon(
            FlutterIcons.check_circle_faw,
            color: Colors.white,
          ),
          title: const Text(
            'My assignments',
            style: ToDoTheme.taskTitleTextStyle,
          ),
        ),
        ListTile(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ToDoBookmarkScreen(),
              ),
            );
          },
          leading: const Icon(
            FlutterIcons.bookmark_mdi,
            color: Colors.white,
          ),
          title: const Text(
            'Bookmarks',
            style: ToDoTheme.taskTitleTextStyle,
          ),
        ),
        ListTile(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const MyRecentActivityScreen(),
              ),
            );
          },
          leading: const Icon(
            FlutterIcons.pie_chart_ent,
            color: Colors.white,
          ),
          title: const Text(
            'My recent activity',
            style: ToDoTheme.taskTitleTextStyle,
          ),
        ),
        ListTile(
          onTap: () {
            showNotYetImplementedMsg(
                context, 'Upcoming events is not yet Implemented');
          },
          leading: const Icon(
            FlutterIcons.event_mdi,
            color: Colors.white,
          ),
          title: const Text(
            'Upcoming event',
            style: ToDoTheme.taskTitleTextStyle,
          ),
        ),
      ],
    );
  }
}
