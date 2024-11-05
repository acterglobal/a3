import 'package:acter/features/tasks/models/tasks.dart';
import 'package:acter/features/tasks/providers/notifiers.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';

//List of task items based on the specified task list
final taskItemsListProvider = AsyncNotifierProvider.family<
    TaskItemsListNotifier, TasksOverview, TaskList>(() {
  return TaskItemsListNotifier();
});

class TaskNotFound extends Error {}

typedef TaskQuery = ({String taskListId, String taskId});

final notifierTaskProvider =
    AsyncNotifierProvider.family<TaskItemNotifier, Task, Task>(() {
  return TaskItemNotifier();
});

//Single Task Item Details Provider based on the TaskList Id and Task Item Id
final taskItemProvider =
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
