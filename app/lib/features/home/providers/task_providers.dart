import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/tasks/models/tasks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:core';

final myTasksProvider = FutureProvider<List<TaskBrief>>((ref) async {
  final client = ref.watch(clientProvider)!;
  // FIXME: how to get informed about updates!?!
  final taskLists = await client.taskLists();
  final myTasks = List<TaskBrief>.empty(growable: true);
  for (final tl in taskLists) {
    final tasks = await tl.tasks();
    for (final task in tasks) {
      // if (task.assignees().contains(my_id)) {
      myTasks.add(await fromTask(tl, task));
      // }
    }
  }
  return myTasks;
});
