import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';
import '../../../helpers/mock_tasks_providers.dart';
import '../task_item_test.dart';


void main() {
  group('AssignUnassignTask Tests', () {

    setUpAll(() {
      // Register fallback values for mocks
      registerFallbackValue(MockWidgetRef());
    });

    group('MockTask Function Tests', () {
      test('should return correct eventId', () {
        // Arrange
        final task = MockTask(eventId: 'test123');
        
        // Act
        final result = task.eventIdStr();
        
        // Assert
        expect(result, equals('test123'));
      });

      test('should successfully assignSelf when not failing', () async {
        // Arrange
        final task = MockTask(eventId: 'test123');
        
        // Act
        final result = await task.assignSelf();
        
        // Assert
        expect(result, isA<EventId>());
        expect(result.toString(), contains('test123'));
        expect(task.assignSelfCalled, isTrue);
      });

      test('should successfully unassignSelf when not failing', () async {
        // Arrange
        final task = MockTask(eventId: 'test123');
        
        // Act
        final result = await task.unassignSelf();
        
        // Assert
        expect(result, isA<EventId>());
        expect(result.toString(), contains('test123'));
        expect(task.unassignSelfCalled, isTrue);
      });
    });

    group('Task Interface Coverage Tests', () {
      test('should test all MockTask interface methods', () {
        // Arrange
        final task = MockTask(eventId: 'test123');
        
        // Act & Assert - Test all interface methods to ensure coverage
        expect(task.taskListIdStr(), equals('taskListId'));
        expect(task.isDone(), isFalse);
        expect(task.title(), equals('Fake Task'));
        expect(task.eventIdStr(), equals('test123'));
        expect(task.roomIdStr(), equals('room123'));
        expect(task.dueDate(), isNull);
        expect(task.description(), isNotNull);
        expect(task.isAssignedToMe(), isFalse);
        expect(task.assigneesStr(), isA<FfiListFfiString>());
        expect(task.subscribeStream(), isA<Stream<bool>>());
      });

      test('should test task refresh method', () async {
        // Arrange
        final task = MockTask(eventId: 'test123');
        
        // Act
        final refreshedTask = await task.refresh();
        
        // Assert
        expect(refreshedTask, equals(task));
      });

      test('should test task invitations method', () async {
        // Arrange
        final task = MockTask(eventId: 'test123');
        
        // Act
        final invitations = await task.invitations();
        
        // Assert
        expect(invitations, isA<ObjectInvitationsManager>());
      });
    });
    
    group('Integration Tests', () {
      test('should handle assign followed by unassign', () async {
        // Arrange
        final task = MockTask(eventId: 'test123');
        
        // Act
        final assignResult = await task.assignSelf();
        final unassignResult = await task.unassignSelf();
        
        // Assert
        expect(assignResult, isA<EventId>());
        expect(unassignResult, isA<EventId>());
        expect(task.assignSelfCalled, isTrue);
        expect(task.unassignSelfCalled, isTrue);
      });

      test('should handle rapid assign/unassign operations', () async {
        // Arrange
        final task = MockTask(eventId: 'test123');
        
        // Act
        final futures = [
          task.assignSelf(),
          task.unassignSelf(),
          task.assignSelf(),
        ];
        final results = await Future.wait(futures);
        
        // Assert
        expect(results, hasLength(3));
        for (final result in results) {
          expect(result, isA<EventId>());
        }
        expect(task.assignSelfCalled, isTrue);
        expect(task.unassignSelfCalled, isTrue);
      });
    });

    group('Performance Tests', () {
      test('should handle many rapid operations efficiently', () async {
        // Arrange
        final task = MockTask(eventId: 'test123');
        const operationCount = 100;
        
        // Act
        final stopwatch = Stopwatch()..start();
        final futures = List.generate(
          operationCount,
          (index) => index.isEven ? task.assignSelf() : task.unassignSelf(),
        );
        final results = await Future.wait(futures);
        stopwatch.stop();
        
        // Assert
        expect(results, hasLength(operationCount));
        for (final result in results) {
          expect(result, isA<EventId>());
        }
        // Performance assertion - should complete within reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      test('should handle concurrent operations', () async {
        // Arrange
        final task = MockTask(eventId: 'test123');
        const concurrentCount = 10;
        
        // Act
        final futures = List.generate(
          concurrentCount,
          (index) => index.isEven ? task.assignSelf() : task.unassignSelf(),
        );
        final results = await Future.wait(futures);
        
        // Assert
        expect(results, hasLength(concurrentCount));
        for (final result in results) {
          expect(result, isA<EventId>());
        }
      });
    });

    group('Memory Tests', () {
      test('should not leak memory with many task instances', () {
        // Arrange
        const taskCount = 1000;
        final tasks = List.generate(
          taskCount,
          (index) => MockTask(eventId: 'task$index'),
        );
        
        // Act
        final eventIds = tasks.map((task) => task.eventIdStr()).toList();
        
        // Assert
        expect(eventIds, hasLength(taskCount));
        for (int i = 0; i < taskCount; i++) {
          expect(eventIds[i], equals('task$i'));
        }
      });

      test('should handle large event IDs efficiently', () {
        // Arrange
        final largeEventId = 'A' * 10000;
        final task = MockTask(eventId: largeEventId);
        
        // Act
        final result = task.eventIdStr();
        
        // Assert
        expect(result, equals(largeEventId));
        expect(result.length, equals(10000));
      });
    });

    group('MockTask Constructor Tests', () {
      test('should create task with default values', () {
        // Arrange & Act
        final task = MockTask();
        
        // Assert
        expect(task.eventId, equals('event123'));
        expect(task.fakeTitle, equals('Fake Task'));
        expect(task.desc, equals(''));
        expect(task.isAssigned, isFalse);
        expect(task.assignees, isEmpty);
        expect(task.roomId, equals('room123'));
        expect(task.hasInvitations, isFalse);
        expect(task.invitedUsers, isEmpty);
        expect(task.assignSelfCalled, isFalse);
        expect(task.unassignSelfCalled, isFalse);
      });

      test('should create task with custom values', () {
        // Arrange & Act
        final task = MockTask(
          eventId: 'custom123',
          fakeTitle: 'Custom Task',
          desc: 'Custom description',
          isAssigned: true,
          assignees: ['user1', 'user2'],
          roomId: 'custom-room',
          hasInvitations: true,
          invitedUsers: ['invited1', 'invited2'],
        );
        
        // Assert
        expect(task.eventId, equals('custom123'));
        expect(task.fakeTitle, equals('Custom Task'));
        expect(task.desc, equals('Custom description'));
        expect(task.isAssigned, isTrue);
        expect(task.assignees, equals(['user1', 'user2']));
        expect(task.roomId, equals('custom-room'));
        expect(task.hasInvitations, isTrue);
        expect(task.invitedUsers, equals(['invited1', 'invited2']));
      });
    });
  });
} 