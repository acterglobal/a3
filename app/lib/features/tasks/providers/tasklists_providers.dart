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
    FutureProvider.family<List<TaskList>, String?>((ref, spaceId) async {
  final allTaskLists = await ref.watch(allTasksListsProvider.future);
  if (spaceId == null) {
    return allTaskLists;
  } else {
    return allTaskLists.where((t) => t.spaceIdStr() == spaceId).toList();
  }
});

//Search any tasks list
typedef TasksListSearchParams = ({String? spaceId, String searchText});

final tasksListSearchProvider = FutureProvider.autoDispose
    .family<List<TaskList>, TasksListSearchParams>((ref, params) async {
  final tasksList = await ref.watch(taskListProvider(params.spaceId).future);

  //Return all task list if search text is empty
  if (params.searchText.isEmpty) return tasksList;

  //Return all task list filter if search text is given
  List<TaskList> filteredTaskList = [];
  for (final taskListItem in tasksList) {
    //Check search param in task list
    if (taskListItem
        .name()
        .toLowerCase()
        .contains(params.searchText.toLowerCase())) {
      filteredTaskList.add(taskListItem);
      continue;
    }

    //Check search param in task list items data
    final tasks = await ref.watch(taskItemsListProvider(taskListItem).future);
    for (final openTaskItem in tasks.openTasks) {
      if (openTaskItem
          .title()
          .toLowerCase()
          .contains(params.searchText.toLowerCase())) {
        filteredTaskList.add(taskListItem);
        break;
      }
    }
  }
  return filteredTaskList;
});
