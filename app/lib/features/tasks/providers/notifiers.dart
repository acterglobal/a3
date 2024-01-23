import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/tasks/models/tasks.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TasksNotifier extends FamilyAsyncNotifier<TasksOverview, TaskList> {
  late Stream<void> _subscriber;
  // ignore: unused_field
  late StreamSubscription<void> _listener;

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
    final retState = _refresh(taskList);
    _subscriber = taskList.subscribeStream();
    _listener = _subscriber.listen((element) async {
      debugPrint('got tasks list update');
      state = await AsyncValue.guard(() async {
        final freshTaskList = await taskList.refresh();
        return await _refresh(freshTaskList);
      });
    });
    return retState;
  }
}

class TaskListNotifier extends FamilyAsyncNotifier<TaskList, String> {
  late Stream<void> _subscriber;
  // ignore: unused_field
  late StreamSubscription<void> _listener;

  Future<TaskList> _refresh(Client client, String taskListId) async {
    return await client.taskList(taskListId, 60);
  }

  @override
  Future<TaskList> build(String arg) async {
    // Load initial todo list from the remote repository
    final client = ref.watch(alwaysClientProvider);
    final taskList = await _refresh(client, arg);
    _subscriber = taskList.subscribeStream();
    _listener = _subscriber.listen((element) async {
      debugPrint('got taskList update');
      state = await AsyncValue.guard(() async {
        return await _refresh(client, arg);
      });
    });
    return taskList;
  }
}

class TaskNotifier extends FamilyAsyncNotifier<Task, Task> {
  late Stream<void> _subscriber;
  // ignore: unused_field
  late StreamSubscription<void> _listener;

  @override
  Future<Task> build(Task arg) async {
    // Load initial todo list from the remote repository
    final task = arg;
    _subscriber = task.subscribeStream();
    _listener = _subscriber.listen((element) async {
      debugPrint('got tasks list update');
      state = await AsyncValue.guard(() async {
        return await task.refresh();
      });
    });
    return task;
  }
}
