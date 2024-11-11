import 'package:acter/features/bookmarks/types.dart';
import 'package:acter/features/bookmarks/util.dart';
import 'package:acter/features/search/providers/quick_search_providers.dart';
import 'package:acter/features/tasks/providers/notifiers.dart';
import 'package:acter/features/tasks/providers/task_items_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';

//Search Value provider for task list
final taskListSearchTermProvider = StateProvider<String>((ref) => '');

//Single Task List Item based on the task list id
final taskListProvider =
    AsyncNotifierProvider.family<TaskListItemNotifier, TaskList, String>(
  () => TaskListItemNotifier(),
);

//List of all task list
final allTasksListsProvider =
    AsyncNotifierProvider<AsyncAllTaskListsNotifier, List<TaskList>>(
  () => AsyncAllTaskListsNotifier(),
);

final taskListsProvider =
    FutureProvider.family<List<String>, String?>((ref, spaceId) async {
  final allTaskLists = await priotizeBookmarked(
    ref,
    BookmarkType.task_lists,
    await ref.watch(allTasksListsProvider.future),
    getId: (e) => e.eventIdStr(),
  );
  if (spaceId == null) {
    return allTaskLists.map((e) => e.eventIdStr()).toList();
  } else {
    return allTaskLists
        .where((t) => t.spaceIdStr() == spaceId)
        .map((e) => e.eventIdStr())
        .toList();
  }
});

final tasksListSearchProvider = FutureProvider.autoDispose
    .family<List<String>, String?>((ref, spaceId) async {
  final tasksList = await ref.watch(taskListsProvider(spaceId).future);
  final searchTerm = ref.watch(taskListSearchTermProvider).trim().toLowerCase();

  //Return all task list if search text is empty
  if (searchTerm.isEmpty) return tasksList;

  //Return all task list filter if search text is given
  return filterTaskListData(ref, tasksList, searchTerm);
});

final taskListQuickSearchedProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final tasksList = await ref.watch(taskListsProvider(null).future);
  final searchTerm = ref.watch(quickSearchValueProvider).trim().toLowerCase();

  //Return all task list if search text is empty
  if (searchTerm.isEmpty) return tasksList;

  //Return all task list filter if search text is given
  return filterTaskListData(ref, tasksList, searchTerm);
});

//Filter taskList with given search term
Future<List<String>> filterTaskListData(
  var ref,
  List<String> tasksList,
  String searchTerm,
) async {
  List<String> filteredTaskList = [];
  for (final taskListId in tasksList) {
    //Check search param in task list
    final taskListItem = await ref.watch(taskListProvider(taskListId).future);
    if (taskListItem.name().toLowerCase().contains(searchTerm)) {
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
      if (openTaskItem.title().toLowerCase().contains(searchTerm)) {
        filteredTaskList.add(taskListId);
        break;
      }
    }
  }
  return filteredTaskList;
}
