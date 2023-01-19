import 'package:effektio/models/ToDoTask.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show TaskDraft, TaskListUpdateBuilder;
import 'package:flutter/widgets.dart';

//Todo List model.
class ToDoList {
  final int? index;
  final String name;
  final String? description;
  final TaskDraft taskDraft;
  final TaskListUpdateBuilder taskUpdateDraft;
  final List<ToDoTask> tasks;
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
    required this.taskDraft,
    required this.taskUpdateDraft,
    this.categories,
    this.subscribers,
    this.color,
    this.description,
    this.tags,
    this.role,
    this.timezone,
  });
}
