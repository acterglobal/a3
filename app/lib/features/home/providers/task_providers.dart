import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';

class MyOpenTasksNotifier extends AsyncNotifier<List<Task>> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _poller;

  @override
  Future<List<Task>> build() async {
    // Load initial todo list from the remote repository
    final client = ref.watch(alwaysClientProvider);
    _listener =
        client.subscribeMyOpenTasksStream(); // keep it resident in memory
    _poller = _listener.listen((element) async {
      state = await AsyncValue.guard(() async => await fetchMyOpenTask(client));
    });
    ref.onDispose(() => _poller.cancel());
    return await fetchMyOpenTask(client);
  }

  Future<List<Task>> fetchMyOpenTask(Client client) async {
    return (await client.myOpenTasks()).toList();
  }
}

final myOpenTasksProvider =
    AsyncNotifierProvider<MyOpenTasksNotifier, List<Task>>(() {
  return MyOpenTasksNotifier();
});
