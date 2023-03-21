import 'package:acter/common/snackbars/not_implemented.dart';
import 'package:acter/features/todo/pages/assignments_page.dart';
import 'package:acter/features/todo/pages/recent_activity_page.dart';
import 'package:acter/features/todo/pages/bookmarks_page.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

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
            Atlas.check_circle,
            color: Colors.white,
          ),
          title: const Text(
            'My assignments',
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
            Atlas.book,
            color: Colors.white,
          ),
          title: const Text(
            'Bookmarks',
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
            Atlas.pie_chart,
            color: Colors.white,
          ),
          title: const Text(
            'My recent activity',
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
            Atlas.calendar_bell,
            color: Colors.white,
          ),
          title: const Text(
            'Upcoming event',
          ),
        ),
      ],
    );
  }
}
