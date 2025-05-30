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
  final Map<TaskDueCategory, List<Task>> _tasks;
  
  const SortedTasks(this._tasks);

  List<Task> get overdue => _tasks[TaskDueCategory.overdue] ?? [];
  List<Task> get today => _tasks[TaskDueCategory.today] ?? [];
  List<Task> get tomorrow => _tasks[TaskDueCategory.tomorrow] ?? [];
  List<Task> get laterThisWeek => _tasks[TaskDueCategory.laterThisWeek] ?? [];
  List<Task> get later => _tasks[TaskDueCategory.later] ?? [];
  List<Task> get noDueDate => _tasks[TaskDueCategory.noDueDate] ?? [];

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
      _tasks[category] ?? [];

  bool hasTasksInCategory(TaskDueCategory category) =>
      (_tasks[category]?.isNotEmpty ?? false);
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