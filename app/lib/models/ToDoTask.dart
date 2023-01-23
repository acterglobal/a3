import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show TaskUpdateBuilder;
import 'package:flutter/widgets.dart';

//Todo task model.
class ToDoTask {
  final int? index;
  final String name;
  final String? description;
  final TaskUpdateBuilder taskUpdateDraft;
  final Color? color;
  final List<String>? assignees;
  final List<String>? categories;
  final List<String>? tags;
  final List<String>? subscribers;
  final int? priority;
  final int progressPercent;
  final DateTime? start;
  final DateTime? due;

  ToDoTask({
    this.index,
    required this.name,
    required this.progressPercent,
    required this.taskUpdateDraft,
    this.assignees,
    this.categories,
    this.tags,
    this.subscribers,
    this.color,
    this.description,
    this.priority,
    this.start,
    this.due,
  });

  /// creates copy of object with updated data.
  ToDoTask copyWith({
    int? index,
    required String name,
    required TaskUpdateBuilder taskUpdateDraft,
    required int progressPercent,
    String? description,
    Color? color,
    List<String>? subscribers,
    List<String>? assignees,
    List<String>? categories,
    List<String>? tags,
    int? priority,
    DateTime? start,
    DateTime? due,
  }) {
    return ToDoTask(
      index: index ?? this.index,
      name: name,
      taskUpdateDraft: taskUpdateDraft,
      progressPercent: progressPercent,
      description: description ?? this.description,
      color: color ?? this.color,
      subscribers: subscribers ?? this.subscribers,
      assignees: assignees ?? this.assignees,
      categories: categories ?? this.categories,
      tags: tags ?? this.tags,
      priority: priority ?? this.priority,
      start: start ?? this.start,
      due: due ?? this.due,
    );
  }
}
