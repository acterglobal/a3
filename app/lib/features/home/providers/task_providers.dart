import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/tasks/actions/my_task_actions.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Client, Task;
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';
import 'package:acter/features/datetime/providers/utc_now_provider.dart';

final _log = Logger('a3::home::task');

class MyOpenTasksNotifier extends AsyncNotifier<List<Task>> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _poller;

  @override
  Future<List<Task>> build() async {
    final client = await ref.watch(alwaysClientProvider.future);
    _listener =
        client.subscribeMyOpenTasksStream(); // keep it resident in memory
    _poller = _listener.listen(
      (data) async {
        state = AsyncValue.data(await fetchMyOpenTask(client));
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

final sortedTasksProvider = FutureProvider<SortedTasks>((ref) async {
  final tasks = await ref.watch(myOpenTasksProvider.future);
  final now = ref.watch(utcNowProvider);  
  
  // Initialize lists for each category
  final overdue = <Task>[];
  final today = <Task>[];
  final tomorrow = <Task>[];
  final laterThisWeek = <Task>[];
  final later = <Task>[];
  final noDueDate = <Task>[];

  // Categorize tasks
  for (final task in tasks) {
    final dueDateStr = task.dueDate();
    final dueDate = dueDateStr != null ? DateTime.parse(dueDateStr) : null;
    final category = getTaskCategory(dueDate, now);
    
    switch (category) {
      case TaskDueCategory.overdue:
        overdue.add(task);
      case TaskDueCategory.today:
        today.add(task);
      case TaskDueCategory.tomorrow:
        tomorrow.add(task);
      case TaskDueCategory.laterThisWeek:
        laterThisWeek.add(task);
      case TaskDueCategory.later:
        later.add(task);
      case TaskDueCategory.noDueDate:
        noDueDate.add(task);
    }
  }

  // Sort overdue tasks by due date (oldest first)
  overdue.sort((a, b) {
    final dateA = DateTime.parse(a.dueDate()!);
    final dateB = DateTime.parse(b.dueDate()!);
    return dateA.compareTo(dateB);
  });

  return SortedTasks(
    overdue: overdue,
    today: today,
    tomorrow: tomorrow,
    laterThisWeek: laterThisWeek,
    later: later,
    noDueDate: noDueDate,
  );
});
