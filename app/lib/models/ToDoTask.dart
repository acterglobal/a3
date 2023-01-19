import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show TaskUpdateBuilder;
import 'package:flutter/widgets.dart';

//Todo task model.
class ToDoTask {
  final int? index;
  final String name;
  final String? description;
  final bool isDone;
  final TaskUpdateBuilder taskUpdateDraft;
  final Color? color;
  final List<String>? assignees;
  final List<String>? categories;
  final List<String>? tags;
  final List<String>? subscribers;
  final int? priority;
  final int? progressPercent;
  final DateTime? start;
  final DateTime? due;

  ToDoTask({
    this.index,
    required this.name,
    required this.isDone,
    required this.taskUpdateDraft,
    this.assignees,
    this.categories,
    this.tags,
    this.subscribers,
    this.color,
    this.description,
    this.priority,
    this.progressPercent,
    this.start,
    this.due,
  });
}
