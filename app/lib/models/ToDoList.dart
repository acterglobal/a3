import 'package:acter/models/Team.dart';
import 'package:acter/models/ToDoTask.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show TaskDraft, TaskListUpdateBuilder;
import 'package:flutter/widgets.dart';

//Todo List model.
class ToDoList {
  final int? index;
  final String name;
  final Team? team;
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

  const ToDoList({
    this.index,
    required this.name,
    this.team,
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

  /// creates copy of object with updated data.
  ToDoList copyWith({
    int? index,
    required String name,
    Team? team,
    String? description,
    required TaskDraft taskDraft,
    required TaskListUpdateBuilder taskUpdateDraft,
    required List<ToDoTask> tasks,
    Color? color,
    List<String>? tags,
    List<String>? subscribers,
    List<String>? categories,
    String? role,
    String? timezone,
  }) {
    return ToDoList(
      index: index ?? this.index,
      name: name,
      team: team ?? this.team,
      tasks: tasks,
      taskDraft: taskDraft,
      taskUpdateDraft: taskUpdateDraft,
      description: description ?? this.description,
      color: color ?? this.color,
      tags: tags ?? this.tags,
      subscribers: subscribers ?? this.subscribers,
      categories: categories ?? this.categories,
      role: role ?? this.role,
      timezone: timezone ?? this.timezone,
    );
  }
}
