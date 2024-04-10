import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/tasks/models/tasks.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::tasks::providers');

class TasksNotifier extends FamilyAsyncNotifier<TasksOverview, TaskList> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _poller;

  Future<TasksOverview> _refresh(TaskList taskList) async {
    final tasks = (await taskList.tasks()).toList();
    List<Task> openTasks = [];
    List<Task> doneTasks = [];
    for (final task in tasks) {
      if (task.isDone()) {
        doneTasks.add(task);
      } else {
        openTasks.add(task);
      }
    }

    // FIXME: ordering?

    return TasksOverview(openTasks: openTasks, doneTasks: doneTasks);
  }

  @override
  Future<TasksOverview> build(TaskList arg) async {
    // Load initial todo list from the remote repository
    final taskList = arg;
    _listener = taskList.subscribeStream(); // keep it resident in memory
    _poller = _listener.listen((element) async {
      _log.info('got tasks list update');
      state = await AsyncValue.guard(() async {
        final freshTaskList = await taskList.refresh();
        return await _refresh(freshTaskList);
      });
    });
    ref.onDispose(() => _poller.cancel());
    return await _refresh(taskList);
  }
}

class TaskListNotifier extends FamilyAsyncNotifier<TaskList, String> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _poller;

  Future<TaskList> _refresh(Client client, String taskListId) async {
    return await client.taskList(taskListId, 60);
  }

  @override
  Future<TaskList> build(String arg) async {
    // Load initial todo list from the remote repository
    final client = ref.watch(alwaysClientProvider);
    final taskList = await _refresh(client, arg);
    _listener = taskList.subscribeStream(); // keep it resident in memory
    _poller = _listener.listen((element) async {
      _log.info('got taskList update');
      state = await AsyncValue.guard(() async => await _refresh(client, arg));
    });
    ref.onDispose(() => _poller.cancel());
    return taskList;
  }
}

class TaskNotifier extends FamilyAsyncNotifier<Task, Task> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _poller;

  @override
  Future<Task> build(Task arg) async {
    // Load initial todo list from the remote repository
    final task = arg;
    _listener = task.subscribeStream(); // keep it resident in memory
    _poller = _listener.listen((element) async {
      _log.info('got tasks list update');
      state = await AsyncValue.guard(() async => await task.refresh());
    });
    ref.onDispose(() => _poller.cancel());
    return task;
  }
}
