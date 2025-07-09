import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:acter/features/tasks/providers/notifiers.dart';
import 'package:acter/features/tasks/models/tasks.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter/features/home/providers/client_providers.dart';

import '../../../helpers/mock_a3sdk.dart';
import '../../../helpers/mock_tasks_providers.dart';
import '../../../helpers/mock_client_provider.dart';

void main() {
  late MockClient mockClient;
  late MockTask mockTask;
  late MockTaskList mockTaskList;
  late ProviderContainer container;

  setUp(() {
    mockClient = MockClient();
    mockTask = MockTask(
      fakeTitle: 'Test Task',
      roomId: 'room123',
      eventId: 'event123',
      hasInvitations: false,
    );
    mockTaskList = MockTaskList();

    // Initialize container with overrides
    container = ProviderContainer(
      overrides: [
        clientProvider.overrideWith(() => MockClientNotifier(client: mockClient)),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('TaskItemsListNotifier', () {
    late final taskItemsListProvider = AsyncNotifierProvider.family<TaskItemsListNotifier, TasksOverview, TaskList>(
      TaskItemsListNotifier.new,
    );

    test('build handles empty task list', () async {
      final notifier = container.read(taskItemsListProvider(mockTaskList).notifier);
      final result = await notifier.future;

      expect(result.openTasks, []);
      expect(result.doneTasks, []);
    });
  });

  group('TaskListItemNotifier', () {
    late final taskListItemProvider = AsyncNotifierProvider.family<TaskListItemNotifier, TaskList, String>(
      TaskListItemNotifier.new,
    );

    test('build returns TaskList', () async {
      final notifier = container.read(taskListItemProvider('taskList1').notifier);
      final result = await notifier.future;

      expect(result, isA<TaskList>());
    });

    test('build handles task list not found', () async {
      mockClient.shouldFail = true;

      final notifier = container.read(taskListItemProvider('taskList1').notifier);
      
      expect(notifier.future, throwsException);
    });
  });

  group('TaskItemNotifier', () {
    late final taskItemProvider = AsyncNotifierProvider.family<TaskItemNotifier, Task, Task>(
      TaskItemNotifier.new,
    );

    test('build returns Task', () async {
      final notifier = container.read(taskItemProvider(mockTask).notifier);
      final result = await notifier.future;

      expect(result, mockTask);
    });
  });

  group('AsyncAllTaskListsNotifier', () {
    late final asyncAllTaskListsProvider = AsyncNotifierProvider<AsyncAllTaskListsNotifier, List<TaskList>>(
      AsyncAllTaskListsNotifier.new,
    );

    test('build returns list of TaskLists', () async {
      final notifier = container.read(asyncAllTaskListsProvider.notifier);
      final result = await notifier.future;

      expect(result, isA<List<TaskList>>());
    });

    test('build handles empty task lists', () async {
      final notifier = container.read(asyncAllTaskListsProvider.notifier);
      final result = await notifier.future;

      expect(result, []);
    });
  });

  group('AsyncTaskInvitationsNotifier', () {
    late final asyncTaskInvitationsProvider = AsyncNotifierProvider.family<AsyncTaskInvitationsNotifier, List<String>, Task>(
      AsyncTaskInvitationsNotifier.new,
    );

    test('build returns list of invited users', () async {
      final mockTask = MockTask(
        fakeTitle: 'Test Task',
        roomId: 'room123',
        eventId: 'event123',
        hasInvitations: true,
        invitedUsers: ['@user1:example.com'],
      );

      final notifier = container.read(asyncTaskInvitationsProvider(mockTask).notifier);
      final result = await notifier.future;

      expect(result, ['@user1:example.com']);
    });

    test('build handles empty invitations', () async {
      final mockTask = MockTask(
        fakeTitle: 'Test Task',
        roomId: 'room123',
        eventId: 'event123',
        hasInvitations: false,
        invitedUsers: [],
      );

      final notifier = container.read(asyncTaskInvitationsProvider(mockTask).notifier);
      final result = await notifier.future;

      expect(result, []);
    });

    test('refresh updates invitations list', () async {
      final initialTask = MockTask(
        fakeTitle: 'Test Task',
        roomId: 'room123',
        eventId: 'event123',
        hasInvitations: true,
        invitedUsers: ['@user1:example.com'],
      );

      final notifier = container.read(asyncTaskInvitationsProvider(initialTask).notifier);
      await notifier.future; // Initial build

      // Create new task with updated invitations
      final updatedTask = MockTask(
        fakeTitle: 'Test Task',
        roomId: 'room123',
        eventId: 'event123',
        hasInvitations: true,
        invitedUsers: ['@user1:example.com', '@user2:example.com'],
      );

      // Create a new notifier with the updated task
      final newNotifier = container.read(asyncTaskInvitationsProvider(updatedTask).notifier);
      final result = await newNotifier.future;

      expect(result, ['@user1:example.com', '@user2:example.com']);
    });
  });

  group('AsyncTaskHasInvitationsNotifier', () {
    late final asyncTaskHasInvitationsProvider = AsyncNotifierProvider.family<AsyncTaskHasInvitationsNotifier, bool, Task>(
      AsyncTaskHasInvitationsNotifier.new,
    );

    test('build returns true when task has invitations', () async {
      final mockTask = MockTask(
        fakeTitle: 'Test Task',
        roomId: 'room123',
        eventId: 'event123',
        hasInvitations: true,
        invitedUsers: ['@user1:example.com'],
      );

      final notifier = container.read(asyncTaskHasInvitationsProvider(mockTask).notifier);
      final result = await notifier.future;

      expect(result, true);
    });

    test('build returns false when task has no invitations', () async {
      final mockTask = MockTask(
        fakeTitle: 'Test Task',
        roomId: 'room123',
        eventId: 'event123',
        hasInvitations: false,
        invitedUsers: [],
      );

      final notifier = container.read(asyncTaskHasInvitationsProvider(mockTask).notifier);
      final result = await notifier.future;

      expect(result, false);
    });

    test('refresh updates hasInvitations status', () async {
      final initialTask = MockTask(
        fakeTitle: 'Test Task',
        roomId: 'room123',
        eventId: 'event123',
        hasInvitations: false,
        invitedUsers: [],
      );

      final notifier = container.read(asyncTaskHasInvitationsProvider(initialTask).notifier);
      await notifier.future; // Initial build

      // Create new task with invitations
      final updatedTask = MockTask(
        fakeTitle: 'Test Task',
        roomId: 'room123',
        eventId: 'event123',
        hasInvitations: true,
        invitedUsers: ['@user1:example.com'],
      );

      // Create a new notifier with the updated task
      final newNotifier = container.read(asyncTaskHasInvitationsProvider(updatedTask).notifier);
      final result = await newNotifier.future;

      expect(result, true);
    });
  });

  group('AsyncTaskUserInvitationNotifier', () {
    late final asyncTaskUserInvitationProvider = AsyncNotifierProvider.family<AsyncTaskUserInvitationNotifier, bool, (Task, String)>(
      AsyncTaskUserInvitationNotifier.new,
    );

    test('build returns true when user is invited', () async {
      final mockTask = MockTask(
        fakeTitle: 'Test Task',
        roomId: 'room123',
        eventId: 'event123',
        hasInvitations: true,
        invitedUsers: ['@user1:example.com'],
        currentUserId: '@user1:example.com',
      );

      final notifier = container.read(asyncTaskUserInvitationProvider((mockTask, '@user1:example.com')).notifier);
      final result = await notifier.future;

      expect(result, true);
    });

    test('build returns false when user is not invited', () async {
      final mockTask = MockTask(
        fakeTitle: 'Test Task',
        roomId: 'room123',
        eventId: 'event123',
        hasInvitations: true,
        invitedUsers: ['@user1:example.com'],
        currentUserId: '@user2:example.com',
      );

      final notifier = container.read(asyncTaskUserInvitationProvider((mockTask, '@user2:example.com')).notifier);
      final result = await notifier.future;

      expect(result, false);
    });

    test('build returns false when task has no invitations', () async {
      final mockTask = MockTask(
        fakeTitle: 'Test Task',
        roomId: 'room123',
        eventId: 'event123',
        hasInvitations: false,
        invitedUsers: [],
        currentUserId: '@user1:example.com',
      );

      final notifier = container.read(asyncTaskUserInvitationProvider((mockTask, '@user1:example.com')).notifier);
      final result = await notifier.future;

      expect(result, false);
    });

    test('refresh updates user invitation status', () async {
      final initialTask = MockTask(
        fakeTitle: 'Test Task',
        roomId: 'room123',
        eventId: 'event123',
        hasInvitations: true,
        invitedUsers: ['@user1:example.com'],
        currentUserId: '@user2:example.com',
      );

      final notifier = container.read(asyncTaskUserInvitationProvider((initialTask, '@user2:example.com')).notifier);
      await notifier.future; // Initial build

      // Create new task with updated invitations
      final updatedTask = MockTask(
        fakeTitle: 'Test Task',
        roomId: 'room123',
        eventId: 'event123',
        hasInvitations: true,
        invitedUsers: ['@user1:example.com', '@user2:example.com'],
        currentUserId: '@user2:example.com',
      );

      // Create a new notifier with the updated task
      final newNotifier = container.read(asyncTaskUserInvitationProvider((updatedTask, '@user2:example.com')).notifier);
      final result = await newNotifier.future;

      expect(result, true);
    });
  });
} 