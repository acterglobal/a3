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
  
  const SortedTasks({
    required this.overdue,
    required this.today,
    required this.tomorrow,
    required this.laterThisWeek,
    required this.later,
    required this.noDueDate,
  });

  List<Task> get allTasks => [
        ...overdue,
        ...today,
        ...tomorrow,
        ...laterThisWeek,
        ...later,
        ...noDueDate,
      ];

  int get totalCount => allTasks.length;

  List<Task> getTasksForCategory(TaskDueCategory category) {
    switch (category) {
      case TaskDueCategory.overdue:
        return overdue;
      case TaskDueCategory.today:
        return today;
      case TaskDueCategory.tomorrow:
        return tomorrow;
      case TaskDueCategory.laterThisWeek:
        return laterThisWeek;
      case TaskDueCategory.later:
        return later;
      case TaskDueCategory.noDueDate:
        return noDueDate;
    }
  }

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