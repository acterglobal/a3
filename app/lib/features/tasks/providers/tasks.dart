import 'package:acter/features/tasks/models/tasks.dart';
import 'package:acter/features/tasks/providers/notifiers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tasksProvider =
    AsyncNotifierProvider.family<TasksNotifier, TasksOverview, TaskList>(() {
  return TasksNotifier();
});

final taskCommentsProvider =
    FutureProvider.autoDispose.family<CommentsManager, Task>((ref, t) async {
  return await t.comments();
});
