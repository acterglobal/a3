import 'dart:async';
import 'package:acter/features/tasks/models/tasks.dart';
import 'package:acter/features/tasks/providers/notifiers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

import '../features/comments/mock_data/mock_message_content.dart';

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

class MockTasksOverview extends Mock implements TasksOverview {}

// Mock TaskItemsListNotifier
class MockAsyncTaskListsNotifier extends Mock implements TaskItemsListNotifier {
  MockAsyncTaskListsNotifier({required this.shouldFail});

  final bool shouldFail;

  Future<List<Task>> loadTasks() async {
    if (shouldFail) {
      throw Exception('Error loading tasks'); // Simulate error
    }
    return []; // Return an empty task list, you can modify it to return any mock tasks
  }

  @override
  Future<TasksOverview> build(TaskList arg) async {
    if (shouldFail) {
      throw Exception('Error building TasksOverview'); // Simulate error
    }

    // Return a mock TasksOverview when build is called
    final mockOverview = MockTasksOverview();
    when(() => mockOverview.openTasks).thenReturn([]); // Simulate no open tasks
    when(
      () => mockOverview.doneTasks,
    ).thenReturn([]); // Simulate no completed tasks

    return mockOverview; // Return the mock TasksOverview
  }
}

class MockTaskListItemNotifier extends Mock implements TaskListItemNotifier {}

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

class MockTaskItemsNotifier extends FamilyAsyncNotifier<Task, Task>
    with Mock
    implements TaskItemNotifier {
  // Indicates whether the mock should succeed or fail
  bool shouldFail;

  MockTaskItemsNotifier({this.shouldFail = true});

  @override
  Future<Task> build(Task task) async {
    if (shouldFail) {
      shouldFail = !shouldFail;
      throw 'Simulated failure';
    }
    return task;
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
  MsgContent? description() {
    // Return the MockMsgContent with the fake description
    return MockMsgContent(bodyText: 'This is a test task description');
  }

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
  final String fakeTitle;
  final String? date;
  final String desc;

  MockTask({this.fakeTitle = 'Fake Task', this.date, this.desc = ''});

  @override
  String taskListIdStr() => 'taskListId';

  @override
  bool isDone() => false;

  @override
  String title() => 'Fake Task';

  @override
  String eventIdStr() => 'eventId';

  @override
  String roomIdStr() => 'roomId';

  @override
  String? dueDate() => date;

  @override
  MsgContent? description() => MockMsgContent(bodyText: desc);

  @override
  bool isAssignedToMe() => false;

  @override
  Future<AttachmentsManager> attachments() =>
      Completer<AttachmentsManager>().future;

  @override
  Future<CommentsManager> comments() => Completer<CommentsManager>().future;

  @override
  FfiListFfiString assigneesStr() {
    final mockAssignees = MockFfiListFfiString();
    // Adding dummy FfiString objects
    mockAssignees.add(MockFfiString('user1'));
    mockAssignees.add(MockFfiString('user2'));
    return mockAssignees;
  }
}

class MockFfiListFfiString extends Mock implements FfiListFfiString {
  final List<FfiString> _strings = [];

  MockFfiListFfiString({List<String> items = const []}) {
    _strings.addAll(items.map((e) => MockFfiString(e)));
  }

  @override
  void add(FfiString value) {
    _strings.add(value);
  }

  List<FfiString> get strings => _strings;

  @override
  int get length => _strings.length;

  @override
  bool get isEmpty => _strings.isEmpty;

  @override
  FfiString operator [](int index) {
    return _strings[index];
  }

  // Corrected to include the growable parameter
  @override
  List<FfiString> toList({bool growable = true}) {
    return List<FfiString>.from(_strings, growable: growable);
  }
}

class MockFfiString extends Mock implements FfiString {
  final String value;

  MockFfiString(this.value);

  @override
  String toDartString() => value;

  @override
  String toString() => value;
}
