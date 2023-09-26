import 'package:acter/features/tasks/models/tasks.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TasksNotifier extends FamilyAsyncNotifier<TasksOverview, TaskList> {
  late Stream<void> subscriber;

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
    subscriber = taskList.subscribeStream();
    subscriber.forEach((element) async {
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() async {
        return await _refresh(taskList);
      });
    });
    return retState;
  }
}
