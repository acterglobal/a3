import 'package:effektio/models/ToDoTask.dart';
import 'package:flutter/widgets.dart';

//Todo List model.
class ToDoList {
  final int index;
  final String name;
  final List<String> categories;
  final Color? color;
  final String? description;
  final List<ToDoTask> tasks;
  final List<String>? tags;
  final List<String> subscribers;
  final String? role;
  final String? timezone;

  ToDoList({
    required this.index,
    required this.name,
    required this.categories,
    required this.tasks,
    required this.subscribers,
    this.color,
    this.description,
    this.tags,
    this.role,
    this.timezone,
  });
}
