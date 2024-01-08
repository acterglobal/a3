import 'dart:core';

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/tasks/models/tasks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final myOpenTasksProvider =
    FutureProvider.autoDispose<List<TaskBrief>>((ref) async {
  final client = ref.watch(alwaysClientProvider);
  // FIXME: how to get informed about updates!?!
  final taskLists = await client.taskLists();
  final myTasks = List<TaskBrief>.empty(growable: true);
  for (final tl in taskLists) {
    final tasks = await tl.tasks();
    for (final task in tasks) {
      if (!task.isDone()) {
        // if (task.assignees().contains(my_id)) {

        final space = tl.space();
        final profile = await ref.watch(spaceProfileDataProvider(space).future);

        myTasks.add(
          TaskBrief(
            task: task,
            taskList: tl,
            space: (space: space, profile: profile),
          ),
        );
        // }
      }
    }
  }
  return myTasks;
});
