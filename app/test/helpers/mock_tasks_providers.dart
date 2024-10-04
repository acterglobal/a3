import 'dart:async';
import 'package:acter/features/tasks/providers/notifiers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:riverpod/riverpod.dart';

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

class MockTaskListItemNotifier extends FamilyAsyncNotifier<TaskList, String>
    with Mock
    implements TaskListItemNotifier {
  bool shouldFail;

  MockTaskListItemNotifier({this.shouldFail = true});

  @override
  Future<MockTaskList> build(String arg) async {
    if (shouldFail) {
      // toggle failure so the retry works
      shouldFail = !shouldFail;
      throw 'Expected fail';
    }

    return MockTaskList();
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

class MockTaskList extends Fake implements TaskList {
  bool shouldFail = true;

  @override
  String name() => 'Test';

  @override
  String spaceIdStr() => 'spaceId';

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

class MockTask extends Fake implements Task {
  @override
  String title() => 'Test';

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
