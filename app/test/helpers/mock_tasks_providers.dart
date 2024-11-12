import 'dart:async';
import 'package:acter/features/tasks/providers/notifiers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

class SimpleReturningTasklists extends AsyncNotifier<List<TaskList>>
    with Mock
    implements AsyncAllTaskListsNotifier {
  final List<TaskList> response;

  SimpleReturningTasklists(this.response);

  @override
  Future<List<TaskList>> build() async => response;
}

class MockAsyncAllTaskListsNotifier extends AsyncNotifier<List<TaskList>>
    with Mock
    implements AsyncAllTaskListsNotifier {
  bool shouldFail;

  MockAsyncAllTaskListsNotifier({this.shouldFail = true});

  @override
  Future<List<TaskList>> build() async {
    if (shouldFail) {
      // toggle failure so the retry works
      shouldFail = !shouldFail;
      throw 'Expected fail';
    }

    return [];
  }
}

class FakeTaskListItemNotifier extends FamilyAsyncNotifier<TaskList, String>
    with Mock
    implements TaskListItemNotifier {
  bool shouldFail;

  FakeTaskListItemNotifier({this.shouldFail = true});

  @override
  Future<FakeTaskList> build(String arg) async {
    if (shouldFail) {
      // toggle failure so the retry works
      shouldFail = !shouldFail;
      throw 'Expected fail';
    }

    return FakeTaskList();
  }
}

class MockTaskItemNotifier extends FamilyAsyncNotifier<Task, Task>
    with Mock
    implements TaskItemNotifier {
  @override
  Future<Task> build(Task arg) async {
    return arg;
  }
}

class MockTaskDraft extends Mock implements TaskDraft {}

class FakeTaskList extends Fake implements TaskList {
  bool shouldFail;

  final String nameStr;
  final String spaceId;
  final String eventId;

  FakeTaskList({
    this.nameStr = 'Test',
    this.spaceId = 'spaceId',
    this.eventId = 'eventId',
    this.shouldFail = true,
  });

  @override
  String eventIdStr() => eventId;

  @override
  String name() => nameStr;

  @override
  String spaceIdStr() => spaceId;

  @override
  MsgContent? description() => null;

  @override
  Display? display() => null;

  @override
  Future<AttachmentsManager> attachments() =>
      Completer<AttachmentsManager>().future;

  @override
  Future<CommentsManager> comments() => Completer<CommentsManager>().future;

  @override
  Future<Task> task(String taskId) async {
    if (shouldFail) {
      shouldFail = false;

      throw 'Expected fail';
    }

    return MockTask();
  }
}

class MockTaskList extends FakeTaskList with Mock {}

class MockTask extends Fake implements Task {
  @override
  bool isDone() => false;

  @override
  String title() => 'Test';

  @override
  String eventIdStr() => 'eventId';

  @override
  MsgContent? description() => null;

  @override
  String? dueDate() => null;

  @override
  bool isAssignedToMe() => false;

  @override
  Future<AttachmentsManager> attachments() =>
      Completer<AttachmentsManager>().future;

  @override
  Future<CommentsManager> comments() => Completer<CommentsManager>().future;

  @override
  Display? display() => null;
}
