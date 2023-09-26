import 'package:acter/features/home/providers/client_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'dart:core';

class AsyncTaskListsNotifier extends AsyncNotifier<List<TaskList>> {
  late Stream<void> subscriber;

  Future<List<TaskList>> _refresh(Client client) async {
    final taskLists = await client.taskLists();
    return taskLists.toList();
  }

  @override
  Future<List<TaskList>> build() async {
    // Load initial todo list from the remote repository
    final client = ref.watch(clientProvider)!;
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

final tasksListsProvider =
    AsyncNotifierProvider<AsyncTaskListsNotifier, List<TaskList>>(() {
  return AsyncTaskListsNotifier();
});

final spaceTasksListsProvider =
    FutureProvider.family<List<TaskList>, String>((ref, spaceId) async {
  final taskLists = await ref.watch(tasksListsProvider.future);
  return taskLists.where((t) => t.spaceIdStr() == spaceId).toList();
});
