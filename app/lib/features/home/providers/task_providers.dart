import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Client, Task;
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::home::task');

class MyOpenTasksNotifier extends AsyncNotifier<List<Task>> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _poller;

  @override
  Future<List<Task>> build() async {
    // Load initial todo list from the remote repository
    final client = await ref.watch(alwaysClientProvider.future);
    _listener =
        client.subscribeMyOpenTasksStream(); // keep it resident in memory
    _poller = _listener.listen(
      (data) async {
        state = AsyncData(await fetchMyOpenTask(client));
      },
      onError: (e, s) {
        _log.severe('stream errored', e, s);
      },
      onDone: () {
        _log.info('stream ended');
      },
    );
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
