import 'package:acter/features/tasks/providers/notifiers.dart';
import 'package:acter/features/tasks/providers/task_items_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';

//Single Task List Item based on the task list id
final taskListItemProvider =
    AsyncNotifierProvider.family<TaskListItemNotifier, TaskList, String>(
  () => TaskListItemNotifier(),
);

//List of all task list
final allTasksListsProvider =
    AsyncNotifierProvider<AsyncAllTaskListsNotifier, List<TaskList>>(
  () => AsyncAllTaskListsNotifier(),
);

final taskListProvider =
    FutureProvider.family<List<String>, String?>((ref, spaceId) async {
  final allTaskLists = await ref.watch(allTasksListsProvider.future);
  if (spaceId == null) {
    return allTaskLists.map((e) => e.eventIdStr()).toList();
  } else {
    return allTaskLists
        .where((t) => t.spaceIdStr() == spaceId)
        .map((e) => e.eventIdStr())
        .toList();
  }
});

//Search any tasks list
typedef TasksListSearchParams = ({String? spaceId, String searchText});

final tasksListSearchProvider = FutureProvider.autoDispose
    .family<List<String>, TasksListSearchParams>((ref, params) async {
  final tasksList = await ref.watch(taskListProvider(params.spaceId).future);

  //Return all task list if search text is empty
  if (params.searchText.isEmpty) return tasksList;

  //Return all task list filter if search text is given
  List<String> filteredTaskList = [];
  for (final taskListId in tasksList) {
    //Check search param in task list
    final taskListItem =
        await ref.watch(taskListItemProvider(taskListId).future);
    if (taskListItem
        .name()
        .toLowerCase()
        .contains(params.searchText.toLowerCase())) {
      filteredTaskList.add(taskListId);
      continue;
    }

    //Check search param in task list items data
    final tasks = await ref.watch(taskItemsListProvider(taskListItem).future);
    for (final openTaskItemId in tasks.openTasks) {
      final openTaskItem = await ref.watch(
        taskItemProvider((taskListId: taskListId, taskId: openTaskItemId))
            .future,
      );
      if (openTaskItem
          .title()
          .toLowerCase()
          .contains(params.searchText.toLowerCase())) {
        filteredTaskList.add(taskListId);
        break;
      }
    }
  }
  return filteredTaskList;
});
