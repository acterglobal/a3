import 'package:acter/common/controllers/client_controller.dart';
import 'package:acter/common/models/profile_data.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:core';

final myTasksProvider = FutureProvider<List<Task>>((ref) async {
  final client = ref.watch(clientProvider)!;
  final my_id = client.userId();
  // FIXME: how to get informed about updates!?!
  final task_lists = await client.taskLists();
  final my_tasks = List<Task>.empty(growable: true);
  for (final tl in task_lists) {
    final tasks = await tl.tasks();
    for (final task in tasks) {
      // if (task.assignees().contains(my_id)) {
      my_tasks.add(task);
      // }
    }
  }
  return my_tasks;
});
