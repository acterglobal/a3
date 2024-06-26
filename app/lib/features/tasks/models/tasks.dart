import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

@immutable
class TasksOverview {
  final List<Task> openTasks;
  final List<Task> doneTasks;
  const TasksOverview({required this.openTasks, required this.doneTasks});
}
