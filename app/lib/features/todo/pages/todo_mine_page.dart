import 'package:effektio/common/snackbars/not_implemented.dart';
import 'package:effektio/common/themes/seperated_themes.dart';
import 'package:effektio/features/todo/pages/assignments_page.dart';
import 'package:effektio/features/todo/pages/recent_activity_page.dart';
import 'package:effektio/features/todo/pages/bookmarks_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';

class ToDoMinePage extends StatefulWidget {
  const ToDoMinePage({Key? key}) : super(key: key);

  @override
  State<ToDoMinePage> createState() => _ToDoMinePageState();
}

class _ToDoMinePageState extends State<ToDoMinePage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AssignmentsPage(),
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
                builder: (context) => const BookmarksPage(),
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
                builder: (context) => const RecentActivityPage(),
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
              context,
              'Upcoming events is not yet Implemented',
            );
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
