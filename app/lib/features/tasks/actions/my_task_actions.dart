import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';

enum TaskDueCategory {
  overdue,
  today,
  tomorrow,
  laterThisWeek,
  later,
  noDueDate;

  bool get isOverdue => this == TaskDueCategory.overdue;

  bool get hasDueDate => this != TaskDueCategory.noDueDate;
}

class SortedTasks {
  final List<Task> overdue;
  final List<Task> today;
  final List<Task> tomorrow;
  final List<Task> laterThisWeek;
  final List<Task> later;
  final List<Task> noDueDate;

  SortedTasks(List<Task> tasks, DateTime now)
    : overdue = <Task>[],
      today = <Task>[],
      tomorrow = <Task>[],
      laterThisWeek = <Task>[],
      later = <Task>[],
      noDueDate = <Task>[] {
        
    for (final task in tasks) {
      final dueDateStr = task.dueDate();
      final dueDate = dueDateStr != null ? DateTime.parse(dueDateStr) : null;
      final category = getTaskCategory(dueDate, now);

      (switch (category) {
        TaskDueCategory.overdue => overdue,
        TaskDueCategory.today => today,
        TaskDueCategory.tomorrow => tomorrow,
        TaskDueCategory.laterThisWeek => laterThisWeek,
        TaskDueCategory.later => later,
        TaskDueCategory.noDueDate => noDueDate,
      }).add(task);
    }

    // Sort overdue tasks by due date (oldest first)
    overdue.sort((a, b) {
      final dateA = DateTime.parse(a.dueDate()!);
      final dateB = DateTime.parse(b.dueDate()!);
      return dateA.compareTo(dateB);
    });
  }

  List<Task> get allTasks => [
    ...overdue,
    ...today,
    ...tomorrow,
    ...laterThisWeek,
    ...later,
    ...noDueDate,
  ];

  int get totalCount => allTasks.length;

  List<Task> getTasksForCategory(TaskDueCategory category) =>
      switch (category) {
        TaskDueCategory.overdue => overdue,
        TaskDueCategory.today => today,
        TaskDueCategory.tomorrow => tomorrow,
        TaskDueCategory.laterThisWeek => laterThisWeek,
        TaskDueCategory.later => later,
        TaskDueCategory.noDueDate => noDueDate,
      };

  bool hasTasksInCategory(TaskDueCategory category) =>
      getTasksForCategory(category).isNotEmpty;
}

TaskDueCategory getTaskCategory(DateTime? dueDate, DateTime now) {
  if (dueDate == null) return TaskDueCategory.noDueDate;
  
  final startOfToday = DateTime(now.year, now.month, now.day);
  final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
  final endOfTomorrow = endOfToday.add(const Duration(days: 1));
  final endOfWeek = endOfToday.add(Duration(days: 7 - now.weekday));

  if (dueDate.isBefore(startOfToday)) return TaskDueCategory.overdue;
  if (dueDate.isBefore(endOfToday)) return TaskDueCategory.today;
  if (dueDate.isBefore(endOfTomorrow)) return TaskDueCategory.tomorrow;
  if (dueDate.isBefore(endOfWeek)) return TaskDueCategory.laterThisWeek;
  return TaskDueCategory.later;
}