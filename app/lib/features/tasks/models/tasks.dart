import 'package:flutter/material.dart';

@immutable
class TasksOverview {
  final List<String> openTasks;
  final List<String> doneTasks;

  const TasksOverview({required this.openTasks, required this.doneTasks});
}
