import 'dart:core';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AsyncTaskListsNotifier extends AsyncNotifier<List<TaskList>> {
  late Stream<void> subscriber;

  Future<List<TaskList>> _refresh(Client client) async {
    final taskLists = await client.taskLists();
    return taskLists.toList();
  }

  @override
  Future<List<TaskList>> build() async {
    // Load initial todo list from the remote repository
    final client = ref.watch(alwaysClientProvider);
    final retState = _refresh(client);
    subscriber = client.subscribeStream('tasks');
    subscriber.forEach((element) async {
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() async {
        return await _refresh(client);
      });
    });
    return retState;
  }
}

final taskListProvider = FutureProvider.autoDispose
    .family<TaskList, String>((ref, taskListId) async {
  final lists = await ref.watch(tasksListsProvider.future);
  for (final list in lists) {
    if (list.eventIdStr() == taskListId) {
      return list;
    }
  }
  throw 'Task List not found';
});

final tasksListsProvider =
    AsyncNotifierProvider<AsyncTaskListsNotifier, List<TaskList>>(() {
  return AsyncTaskListsNotifier();
});

final spaceTasksListsProvider =
    FutureProvider.family<List<TaskList>, String>((ref, spaceId) async {
  final taskLists = await ref.watch(tasksListsProvider.future);
  return taskLists.where((t) => t.spaceIdStr() == spaceId).toList();
});
