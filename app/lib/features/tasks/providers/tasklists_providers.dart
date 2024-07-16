import 'package:acter/features/tasks/providers/notifiers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';

//Single Task List Item based on the task list id
final taskListItemProvider =
    AsyncNotifierProvider.family<TaskListItemNotifier, TaskList, String>(
  () => TaskListItemNotifier(),
);

//List of all task list
//If space Id given then it will return list of space task list
final tasksListsProvider = AsyncNotifierProvider.family<AsyncTaskListsNotifier,
    List<TaskList>, String?>(() => AsyncTaskListsNotifier());

//Search any tasks list
typedef TasksListSearchParams = ({String? spaceId, String searchText});

final tasksListSearchProvider = FutureProvider.autoDispose
    .family<List<TaskList>, TasksListSearchParams>((ref, params) async {
  final tasksList = await ref.watch(tasksListsProvider(params.spaceId).future);
  List<TaskList> filteredTaskList = [];
  for (final task in tasksList) {
    if (task.name().toLowerCase().contains(params.searchText.toLowerCase())) {
      filteredTaskList.add(task);
    }
  }
  return filteredTaskList;
});
