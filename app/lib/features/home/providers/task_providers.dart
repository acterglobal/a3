import 'dart:async';
import 'dart:core';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyOpenTasksNotifier extends AsyncNotifier<List<Task>> {
  late Stream<void> _subscriber;
  // ignore: unused_field
  late StreamSubscription<void> _listener;

  @override
  Future<List<Task>> build() async {
    // Load initial todo list from the remote repository
    final client = ref.watch(alwaysClientProvider);
    _subscriber = client.subscribeMyOpenTasksStream();
    _listener = _subscriber.listen((element) async {
      state = await AsyncValue.guard(() async {
        return await fetchMyOpenTask(client);
      });
    });
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
