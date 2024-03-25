import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/tasks/providers/notifiers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';

class AsyncTaskListsNotifier extends AsyncNotifier<List<TaskList>> {
  late Stream<bool> _listener;

  Future<List<TaskList>> _refresh(Client client) async {
    final taskLists = await client.taskLists();
    return taskLists.toList();
  }

  @override
  Future<List<TaskList>> build() async {
    // Load initial todo list from the remote repository
    final client = ref.watch(alwaysClientProvider);
    _listener = client.subscribeStream('tasks'); // keep it resident in memory
    _listener.forEach((element) async {
      state = await AsyncValue.guard(() async => await _refresh(client));
    });
    return await _refresh(client);
  }
}

final taskListProvider =
    AsyncNotifierProvider.family<TaskListNotifier, TaskList, String>(
  () => TaskListNotifier(),
);

final tasksListsProvider =
    AsyncNotifierProvider<AsyncTaskListsNotifier, List<TaskList>>(
  () => AsyncTaskListsNotifier(),
);

final spaceTasksListsProvider =
    FutureProvider.family<List<TaskList>, String>((ref, spaceId) async {
  final taskLists = await ref.watch(tasksListsProvider.future);
  return taskLists.where((t) => t.spaceIdStr() == spaceId).toList();
});
