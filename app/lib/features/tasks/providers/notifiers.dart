import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/tasks/models/tasks.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Client, Task, TaskList;
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::tasks::notifiers');

//List of task items based on the specified task list
class TaskItemsListNotifier
    extends FamilyAsyncNotifier<TasksOverview, TaskList> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _poller;

  Future<TasksOverview> _refresh(TaskList taskList) async {
    final tasks = (await taskList.tasks()).toList();
    List<String> openTasks = [];
    List<String> doneTasks = [];
    for (final task in tasks) {
      final eventId = task.eventIdStr();
      if (task.isDone()) {
        doneTasks.add(eventId);
      } else {
        openTasks.add(eventId);
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
    _poller = _listener.listen(
      (data) async {
        _log.info('got tasks list update');
        state = await AsyncValue.guard(() async {
          final freshTaskList = await taskList.refresh();
          return await _refresh(freshTaskList);
        });
      },
      onError: (e, s) {
        _log.severe('tasks overview stream errored', e, s);
      },
      onDone: () {
        _log.info('tasks overview stream ended');
      },
    );
    ref.onDispose(() => _poller.cancel());
    return await _refresh(taskList);
  }
}

//Single Task List Item based on the task list id
class TaskListItemNotifier extends FamilyAsyncNotifier<TaskList, String> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _poller;

  Future<TaskList> _refresh(Client client, String taskListId) async {
    return await client.taskList(taskListId, 60);
  }

  @override
  Future<TaskList> build(String arg) async {
    // Load initial todo list from the remote repository
    final client = await ref.watch(alwaysClientProvider.future);
    final taskList = await _refresh(client, arg);
    _listener = taskList.subscribeStream(); // keep it resident in memory
    _poller = _listener.listen(
      (data) async {
        _log.info('got taskList update');
        state = await AsyncValue.guard(() async => await _refresh(client, arg));
      },
      onError: (e, s) {
        _log.severe('tasklist stream errored', e, s);
      },
      onDone: () {
        _log.info('tasklist stream ended');
      },
    );
    ref.onDispose(() => _poller.cancel());
    return taskList;
  }
}

//Single Task Item Details Provider based on the Task Object
class TaskItemNotifier extends FamilyAsyncNotifier<Task, Task> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _poller;

  @override
  Future<Task> build(Task arg) async {
    // Load initial todo list from the remote repository
    final task = arg;
    _listener = task.subscribeStream(); // keep it resident in memory
    _poller = _listener.listen(
      (data) async {
        _log.info('got tasks list update');
        state = await AsyncValue.guard(() async => await task.refresh());
      },
      onError: (e, s) {
        _log.severe('task stream errored', e, s);
      },
      onDone: () {
        _log.info('task stream ended');
      },
    );
    ref.onDispose(() => _poller.cancel());
    return task;
  }
}

//List of all task list
//If space Id given then it will return list of space task list
class AsyncAllTaskListsNotifier extends AsyncNotifier<List<TaskList>> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _poller;

  @override
  Future<List<TaskList>> build() async {
    final client = await ref.watch(alwaysClientProvider.future);

    //GET ALL TASKS LIST
    _listener = client.subscribeStream('tasks');

    _poller = _listener.listen(
      (data) async {
        state = await AsyncValue.guard(() async => await _getTasksList(client));
      },
      onError: (e, s) {
        _log.severe('all tasks stream errored', e, s);
      },
      onDone: () {
        _log.info('all tasks stream ended');
      },
    );
    ref.onDispose(() => _poller.cancel());

    return await _getTasksList(client);
  }

  Future<List<TaskList>> _getTasksList(Client client) async {
    //GET ALL TASKS LIST
    return (await client.taskLists()).toList();
  }
}
