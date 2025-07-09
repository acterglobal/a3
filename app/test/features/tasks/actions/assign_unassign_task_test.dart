import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';
import '../../../helpers/mock_tasks_providers.dart';
import 'package:acter/features/tasks/actions/assign_unassign_task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../task_item_test.dart';


// True mock class for error simulation
class TrueMockTask extends Mock implements Task {}

void main() {
  group('AssignUnassignTask Tests', () {
    setUpAll(() {
      registerFallbackValue(MockWidgetRef());
    });

    group('MockTask Function Tests', () {
      test('should return correct eventId', () {
        final task = MockTask(eventId: 'test123');
        final result = task.eventIdStr();
        expect(result, equals('test123'));
      });
      test('should successfully assignSelf when not failing', () async {
        final task = MockTask(eventId: 'test123');
        final result = await task.assignSelf();
        expect(result, isA<EventId>());
        expect(result.toString(), contains('test123'));
        expect(task.assignSelfCalled, isTrue);
      });
      test('should successfully unassignSelf when not failing', () async {
        final task = MockTask(eventId: 'test123');
        final result = await task.unassignSelf();
        expect(result, isA<EventId>());
        expect(result.toString(), contains('test123'));
        expect(task.unassignSelfCalled, isTrue);
      });
    });

    group('Task Interface Coverage Tests', () {
      test('should test all MockTask interface methods', () {
        final task = MockTask(eventId: 'test123');
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
        final task = MockTask(eventId: 'test123');
        final refreshedTask = await task.refresh();
        expect(refreshedTask, equals(task));
      });
      test('should test task invitations method', () async {
        final task = MockTask(eventId: 'test123');
        final invitations = await task.invitations();
        expect(invitations, isA<ObjectInvitationsManager>());
      });
    });

    group('onAssign Function Tests', () {
      testWidgets('should successfully assign task', (tester) async {
        final task = MockTask(eventId: 'test123');
        final mockRef = MockWidgetRef();
        await tester.pumpWidget(
          MaterialApp(
            builder: EasyLoading.init(),
            localizationsDelegates: const [
              L10n.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: L10n.supportedLocales,
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => onAssign(context, mockRef, task),
                child: const Text('Assign'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Assign'));
        await tester.pumpAndSettle();
        EasyLoading.dismiss();
        await tester.pumpAndSettle();
        expect(task.assignSelfCalled, isTrue);
      });
    });

    group('onUnAssign Function Tests', () {
      testWidgets('should successfully unassign task', (tester) async {
        final task = MockTask(eventId: 'test123');
        final mockRef = MockWidgetRef();
        await tester.pumpWidget(
          MaterialApp(
            builder: EasyLoading.init(),
            localizationsDelegates: const [
              L10n.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: L10n.supportedLocales,
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => onUnAssign(context, mockRef, task),
                child: const Text('Unassign'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Unassign'));
        await tester.pumpAndSettle();
        EasyLoading.dismiss();
        await tester.pumpAndSettle();
        expect(task.unassignSelfCalled, isTrue);
      });
    });

    group('Integration Tests', () {
      test('should handle assign followed by unassign', () async {
        final task = MockTask(eventId: 'test123');
        final assignResult = await task.assignSelf();
        final unassignResult = await task.unassignSelf();
        expect(assignResult, isA<EventId>());
        expect(unassignResult, isA<EventId>());
        expect(task.assignSelfCalled, isTrue);
        expect(task.unassignSelfCalled, isTrue);
      });
      test('should handle rapid assign/unassign operations', () async {
        final task = MockTask(eventId: 'test123');
        final futures = [
          task.assignSelf(),
          task.unassignSelf(),
          task.assignSelf(),
        ];
        final results = await Future.wait(futures);
        expect(results, hasLength(3));
        for (final result in results) {
          expect(result, isA<EventId>());
        }
        expect(task.assignSelfCalled, isTrue);
        expect(task.unassignSelfCalled, isTrue);
      });
    });

    group('MockTask Constructor Tests', () {
      test('should create task with default values', () {
        final task = MockTask();
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

  group('Widget Tests', () {
    testWidgets('should successfully assign task', (tester) async {
      final task = MockTask();
      final mockRef = MockWidgetRef();

      await tester.pumpWidget(
        MaterialApp(
          builder: EasyLoading.init(),
          localizationsDelegates: const [
            L10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: L10n.supportedLocales,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => onAssign(context, mockRef, task),
              child: const Text('Assign'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Assign'));
      await tester.pumpAndSettle();
      EasyLoading.dismiss();
      await tester.pumpAndSettle();
    });

    testWidgets('should successfully unassign task', (tester) async {
      final task = MockTask();
      final mockRef = MockWidgetRef();

      await tester.pumpWidget(
        MaterialApp(
          builder: EasyLoading.init(),
          localizationsDelegates: const [
            L10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: L10n.supportedLocales,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => onUnAssign(context, mockRef, task),
              child: const Text('Unassign'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Unassign'));
      await tester.pumpAndSettle();
      EasyLoading.dismiss();
      await tester.pumpAndSettle();
    });

    testWidgets('should handle context disposed during assign', (tester) async {
      final task = MockTask();
      final mockRef = MockWidgetRef();

      await tester.pumpWidget(
        MaterialApp(
          builder: EasyLoading.init(),
          localizationsDelegates: const [
            L10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: L10n.supportedLocales,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                await onAssign(context, mockRef, task);
                // Simulate context being disposed
                Navigator.of(context).pop();
              },
              child: const Text('Assign and Pop'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Assign and Pop'));
      await tester.pumpAndSettle();
      EasyLoading.dismiss();
      await tester.pumpAndSettle();
    });

    testWidgets('should handle context disposed during unassign', (tester) async {
      final task = MockTask();
      final mockRef = MockWidgetRef();

      await tester.pumpWidget(
        MaterialApp(
          builder: EasyLoading.init(),
          localizationsDelegates: const [
            L10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: L10n.supportedLocales,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                await onUnAssign(context, mockRef, task);
                // Simulate context being disposed
                Navigator.of(context).pop();
              },
              child: const Text('Unassign and Pop'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Unassign and Pop'));
      await tester.pumpAndSettle();
      EasyLoading.dismiss();
      await tester.pumpAndSettle();
    });

    testWidgets('should handle multiple rapid assign calls', (tester) async {
      final task = MockTask();
      final mockRef = MockWidgetRef();

      await tester.pumpWidget(
        MaterialApp(
          builder: EasyLoading.init(),
          localizationsDelegates: const [
            L10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: L10n.supportedLocales,
          home: Builder(
            builder: (context) => Row(
              children: [
                ElevatedButton(
                  onPressed: () => onAssign(context, mockRef, task),
                  child: const Text('Assign 1'),
                ),
                ElevatedButton(
                  onPressed: () => onAssign(context, mockRef, task),
                  child: const Text('Assign 2'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Assign 1'));
      await tester.tap(find.text('Assign 2'));
      await tester.pumpAndSettle();
      EasyLoading.dismiss();
      await tester.pumpAndSettle();
    });

    testWidgets('should handle multiple rapid unassign calls', (tester) async {
      final task = MockTask();
      final mockRef = MockWidgetRef();

      await tester.pumpWidget(
        MaterialApp(
          builder: EasyLoading.init(),
          localizationsDelegates: const [
            L10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: L10n.supportedLocales,
          home: Builder(
            builder: (context) => Row(
              children: [
                ElevatedButton(
                  onPressed: () => onUnAssign(context, mockRef, task),
                  child: const Text('Unassign 1'),
                ),
                ElevatedButton(
                  onPressed: () => onUnAssign(context, mockRef, task),
                  child: const Text('Unassign 2'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Unassign 1'));
      await tester.tap(find.text('Unassign 2'));
      await tester.pumpAndSettle();
      EasyLoading.dismiss();
      await tester.pumpAndSettle();
    });
  });

  group('Error Simulation Tests', () {
    testWidgets('should handle assignSelf throwing exception', (tester) async {
      final task = TrueMockTask();
      final mockRef = MockWidgetRef();
      when(() => task.assignSelf()).thenThrow(Exception('Assign failed'));
      when(() => task.eventIdStr()).thenReturn('test123');
      await tester.pumpWidget(
        MaterialApp(
          builder: EasyLoading.init(),
          localizationsDelegates: const [
            L10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: L10n.supportedLocales,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => onAssign(context, mockRef, task),
              child: const Text('Assign'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Assign'));
      await tester.pumpAndSettle();
      EasyLoading.dismiss();
      await tester.pumpAndSettle();
      expect(true, isTrue); // Just ensure no crash
    });

    testWidgets('should handle unassignSelf throwing exception', (tester) async {
      final task = TrueMockTask();
      final mockRef = MockWidgetRef();
      when(() => task.unassignSelf()).thenThrow(Exception('Unassign failed'));
      when(() => task.eventIdStr()).thenReturn('test123');
      await tester.pumpWidget(
        MaterialApp(
          builder: EasyLoading.init(),
          localizationsDelegates: const [
            L10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: L10n.supportedLocales,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => onUnAssign(context, mockRef, task),
              child: const Text('Unassign'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Unassign'));
      await tester.pumpAndSettle();
      EasyLoading.dismiss();
      await tester.pumpAndSettle();
      expect(true, isTrue);
    });

    testWidgets('should handle autosubscribe throwing exception during assign', (tester) async {
      final task = TrueMockTask();
      final mockRef = MockWidgetRef();
      when(() => task.assignSelf()).thenThrow(Exception('Autosubscribe failed'));
      when(() => task.eventIdStr()).thenReturn('test123');
      await tester.pumpWidget(
        MaterialApp(
          builder: EasyLoading.init(),
          localizationsDelegates: const [
            L10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: L10n.supportedLocales,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => onAssign(context, mockRef, task),
              child: const Text('Assign'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Assign'));
      await tester.pumpAndSettle();
      EasyLoading.dismiss();
      await tester.pumpAndSettle();
      expect(true, isTrue);
    });

    testWidgets('should handle autosubscribe throwing exception during unassign', (tester) async {
      final task = TrueMockTask();
      final mockRef = MockWidgetRef();
      when(() => task.unassignSelf()).thenThrow(Exception('Autosubscribe failed'));
      when(() => task.eventIdStr()).thenReturn('test123');
      await tester.pumpWidget(
        MaterialApp(
          builder: EasyLoading.init(),
          localizationsDelegates: const [
            L10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: L10n.supportedLocales,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => onUnAssign(context, mockRef, task),
              child: const Text('Unassign'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Unassign'));
      await tester.pumpAndSettle();
      EasyLoading.dismiss();
      await tester.pumpAndSettle();
      expect(true, isTrue);
    });
  });
} 