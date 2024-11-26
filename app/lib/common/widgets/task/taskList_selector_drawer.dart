import 'package:acter/features/tasks/pages/tasks_list_page.dart';
import 'package:flutter/material.dart';

const Key selectPinDrawerKey = Key('select-pin-drawer');

Future<String?> selectTaskDrawer({
  required BuildContext context,
  String? spaceId,
}) async {
  final taskListId = await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    builder: (context) => TasksListPage(
      spaceId: spaceId,
      showOnlyTaskList: true,
      onSelectTaskListItem: (taskListId) => Navigator.pop(context, taskListId),
    ),
  );
  return taskListId == '' ? null : taskListId;
}
