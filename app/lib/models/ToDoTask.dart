import 'package:flutter/widgets.dart';

//Todo task model.
class ToDoTask {
  final int index;
  final String name;
  final List<String> assignees;
  final List<String> categories;
  final Color? color;
  final String? description;
  final bool isDone;
  final List<String> tags;
  final List<String> subscribers;
  final int? priority;
  final int? progressPercent;
  final DateTime? start;
  final DateTime? due;

  ToDoTask({
    required this.index,
    required this.name,
    required this.assignees,
    required this.categories,
    required this.isDone,
    required this.tags,
    required this.subscribers,
    this.color,
    this.description,
    this.priority,
    this.progressPercent,
    this.start,
    this.due,
  });
}
