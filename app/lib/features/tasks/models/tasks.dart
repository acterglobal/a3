import 'package:acter/common/models/profile_data.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class TaskBrief {
  final Task task;
  final TaskList taskList;
  final SpaceWithProfileData space;

  const TaskBrief({
    required this.task,
    required this.taskList,
    required this.space,
  });
}

@immutable
class TasksOverview {
  final List<Task> openTasks;
  final List<Task> doneTasks;
  const TasksOverview({required this.openTasks, required this.doneTasks});
}
