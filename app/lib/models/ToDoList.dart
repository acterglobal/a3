import 'package:effektio/models/ToDoTask.dart';
import 'package:flutter/widgets.dart';

//Todo List model.
class ToDoList {
  final int? index;
  final String name;
  final String? description;
  final List<ToDoTask> tasks;
  final int? completedTasks;
  final int? pendingTasks;
  final Color? color;
  final List<String>? tags;
  final List<String>? subscribers;
  final List<String>? categories;
  final String? role;
  final String? timezone;

  ToDoList({
    this.index,
    required this.name,
    required this.tasks,
    this.completedTasks,
    this.pendingTasks,
    this.categories,
    this.subscribers,
    this.color,
    this.description,
    this.tags,
    this.role,
    this.timezone,
  });
}
