import 'package:acter/features/tasks/actions/my_task_actions.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/mock_tasks_providers.dart';

void main() {
  late DateTime now;

  setUp(() {
    now = DateTime(2024, 3, 15, 12, 0); // A Friday
  });

  group('SortedTasks.fromTasks', () {
    test('should categorize tasks correctly', () {
      final tasks = [
        MockTask(date: '2024-03-14'), // overdue
        MockTask(date: '2024-03-15'), // today
        MockTask(date: '2024-03-16'), // tomorrow
        MockTask(date: '2024-03-17'), // later this week
        MockTask(date: '2024-03-20'), // later
        MockTask(date: null), // no due date
      ];

      final sortedTasks = SortedTasks.fromTasks(tasks, now);

      expect(sortedTasks.overdue.length, 1);
      expect(sortedTasks.today.length, 1);
      expect(sortedTasks.tomorrow.length, 1);
      expect(sortedTasks.laterThisWeek.length, 1);
      expect(sortedTasks.later.length, 1);
      expect(sortedTasks.noDueDate.length, 1);
    });

    test('should sort overdue tasks by date', () {
      final tasks = [
        MockTask(date: '2024-03-14'),
        MockTask(date: '2024-03-13'),
        MockTask(date: '2024-03-12'),
      ];

      final sortedTasks = SortedTasks.fromTasks(tasks, now);

      expect(sortedTasks.overdue.length, 3);
      expect(
        sortedTasks.overdue.map((t) => t.dueDate()).toList(),
        ['2024-03-12', '2024-03-13', '2024-03-14'],
      );
    });

    test('should handle empty task list', () {
      final sortedTasks = SortedTasks.fromTasks([], now);

      expect(sortedTasks.totalCount, 0);
      expect(sortedTasks.allTasks, isEmpty);
    });

    test('should correctly identify tasks in each category', () {
      final tasks = [
        MockTask(date: '2024-03-14'), // overdue
        MockTask(date: '2024-03-15'), // today
        MockTask(date: '2024-03-16'), // tomorrow
        MockTask(date: '2024-03-17'), // later this week
        MockTask(date: '2024-03-20'), // later
        MockTask(date: null), // no due date
      ];

      final sortedTasks = SortedTasks.fromTasks(tasks, now);

      expect(sortedTasks.hasTasksInCategory(TaskDueCategory.overdue), true);
      expect(sortedTasks.hasTasksInCategory(TaskDueCategory.today), true);
      expect(sortedTasks.hasTasksInCategory(TaskDueCategory.tomorrow), true);
      expect(sortedTasks.hasTasksInCategory(TaskDueCategory.laterThisWeek), true);
      expect(sortedTasks.hasTasksInCategory(TaskDueCategory.later), true);
      expect(sortedTasks.hasTasksInCategory(TaskDueCategory.noDueDate), true);
    });
  });
}