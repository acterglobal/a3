import 'package:acter/features/tasks/actions/my_task_actions.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/mock_tasks_providers.dart';

void main() {
  group('getTaskCategory', () {
    test('returns noDueDate when dueDate is null', () {
      final now = DateTime(2024, 3, 15, 12, 0); // Friday
      expect(getTaskCategory(null, now), equals(TaskDueCategory.noDueDate));
    });

    test('returns overdue when dueDate is before today', () {
      final now = DateTime(2024, 3, 15, 12, 0); // Friday
      final yesterday = DateTime(2024, 3, 14, 12, 0);
      expect(getTaskCategory(yesterday, now), equals(TaskDueCategory.overdue));
    });

    test('returns today when dueDate is today', () {
      final now = DateTime(2024, 3, 15, 12, 0); // Friday
      final today = DateTime(2024, 3, 15, 15, 0);
      expect(getTaskCategory(today, now), equals(TaskDueCategory.today));
    });

    test('returns tomorrow when dueDate is end of today', () {
      final now = DateTime(2024, 3, 15, 12, 0); // Friday
      final endOfToday = DateTime(2024, 3, 15, 23, 59, 59);
      expect(getTaskCategory(endOfToday, now), equals(TaskDueCategory.tomorrow));
    });

    test('returns tomorrow when dueDate is tomorrow', () {
      final now = DateTime(2024, 3, 15, 12, 0); // Friday
      final tomorrow = DateTime(2024, 3, 16, 12, 0);
      expect(getTaskCategory(tomorrow, now), equals(TaskDueCategory.tomorrow));
    });

    test('returns later when dueDate is within this week', () {
      final now = DateTime(2024, 3, 15, 12, 0); // Friday
      final endOfWeek = DateTime(2024, 3, 17, 23, 59, 59); // Sunday
      expect(getTaskCategory(endOfWeek, now), equals(TaskDueCategory.later));
    });

    test('returns later when dueDate is after this week', () {
      final now = DateTime(2024, 3, 15, 12, 0); // Friday
      final nextWeek = DateTime(2024, 3, 18, 12, 0); // Monday
      expect(getTaskCategory(nextWeek, now), equals(TaskDueCategory.later));
    });
  });

  group('SortedTasks', () {
    late DateTime now;
    late List<Task> tasks;

    setUp(() {
      now = DateTime(2024, 3, 15, 12, 0); // Friday
      tasks = [
        // Overdue tasks
        MockTask(date: '2024-03-14T12:00:00'), // Yesterday
        MockTask(date: '2024-03-13T12:00:00'), // Day before yesterday
        
        // Today's tasks
        MockTask(date: '2024-03-15T15:00:00'), // Today afternoon
        MockTask(date: '2024-03-15T23:59:59'), // End of today (categorized as tomorrow)
        
        // Tomorrow's tasks
        MockTask(date: '2024-03-16T12:00:00'), // Tomorrow
        
        // Later this week (categorized as later)
        MockTask(date: '2024-03-17T12:00:00'), // Sunday
        
        // Later
        MockTask(date: '2024-03-18T12:00:00'), // Next week
        
        // No due date
        MockTask(date: null),
      ];
    });

    test('categorizes tasks correctly', () {
      final sortedTasks = SortedTasks(tasks, now);
      
      expect(sortedTasks.overdue.length, equals(2));
      expect(sortedTasks.today.length, equals(1));
      expect(sortedTasks.tomorrow.length, equals(2));
      expect(sortedTasks.laterThisWeek.length, equals(1));
      expect(sortedTasks.later.length, equals(1));
      expect(sortedTasks.noDueDate.length, equals(1));
    });

    test('sorts overdue tasks by due date', () {
      final sortedTasks = SortedTasks(tasks, now);
      
      // Verify overdue tasks are sorted (oldest first)
      final overdueDates = sortedTasks.overdue.map((t) => DateTime.parse(t.dueDate()!)).toList();
      expect(overdueDates[0].isBefore(overdueDates[1]), isTrue);
    });

    test('hasTasksInCategory returns correct value', () {
      final sortedTasks = SortedTasks(tasks, now);
      
      expect(sortedTasks.hasTasksInCategory(TaskDueCategory.overdue), isTrue);
      expect(sortedTasks.hasTasksInCategory(TaskDueCategory.today), isTrue);
      expect(sortedTasks.hasTasksInCategory(TaskDueCategory.tomorrow), isTrue);
      expect(sortedTasks.hasTasksInCategory(TaskDueCategory.laterThisWeek), isTrue);
      expect(sortedTasks.hasTasksInCategory(TaskDueCategory.later), isTrue);
      expect(sortedTasks.hasTasksInCategory(TaskDueCategory.noDueDate), isTrue);
    });

    test('getTasksForCategory returns correct tasks', () {
      final sortedTasks = SortedTasks(tasks, now);
      
      expect(sortedTasks.getTasksForCategory(TaskDueCategory.overdue), equals(sortedTasks.overdue));
      expect(sortedTasks.getTasksForCategory(TaskDueCategory.today), equals(sortedTasks.today));
      expect(sortedTasks.getTasksForCategory(TaskDueCategory.tomorrow), equals(sortedTasks.tomorrow));
      expect(sortedTasks.getTasksForCategory(TaskDueCategory.laterThisWeek), equals(sortedTasks.laterThisWeek));
      expect(sortedTasks.getTasksForCategory(TaskDueCategory.later), equals(sortedTasks.later));
      expect(sortedTasks.getTasksForCategory(TaskDueCategory.noDueDate), equals(sortedTasks.noDueDate));
    });

    test('allTasks contains all tasks', () {
      final sortedTasks = SortedTasks(tasks, now);
      
      expect(sortedTasks.allTasks.length, equals(tasks.length));
      expect(sortedTasks.totalCount, equals(tasks.length));
    });
  });
}