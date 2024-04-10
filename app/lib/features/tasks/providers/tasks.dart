import 'package:acter/features/tasks/models/tasks.dart';
import 'package:acter/features/tasks/providers/notifiers.dart';
import 'package:acter/features/tasks/providers/tasklists.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';

final tasksProvider =
    AsyncNotifierProvider.family<TasksNotifier, TasksOverview, TaskList>(() {
  return TasksNotifier();
});

class TaskNotFound extends Error {}

typedef TaskQuery = ({String taskListId, String taskId});

final notifierTaskProvider =
    AsyncNotifierProvider.family<TaskNotifier, Task, Task>(() {
  return TaskNotifier();
});

final taskProvider =
    FutureProvider.autoDispose.family<Task, TaskQuery>((ref, query) async {
  final taskList = await ref.watch(taskListProvider(query.taskListId).future);
  final task = await taskList.task(query.taskId);
  return await ref
      .watch(notifierTaskProvider(task).future); // ensure we stay updated
});

final taskCommentsProvider =
    FutureProvider.autoDispose.family<CommentsManager, Task>((ref, t) async {
  return await t.comments();
});
