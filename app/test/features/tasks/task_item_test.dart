import 'package:acter/common/models/types.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/room/room_avatar_builder.dart';
import 'package:acter/features/tasks/providers/task_items_providers.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter/features/tasks/widgets/task_item.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:dart_date/dart_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mockingjay/mockingjay.dart';
import '../../helpers/mock_go_router.dart';
import '../../helpers/mock_tasks_providers.dart';
import '../../helpers/test_util.dart';

class MockOnTapTaskItem extends Mock {
  void call(String taskId);
}

class MockWidgetRef extends Mock implements WidgetRef {}

class MockBuildContext extends Mock implements BuildContext {}

class MockMemberDisplayNameProvider extends Mock {
  Future<String?> call(MemberInfo query) async {
    // Simulating return value
    return query.userId == 'test' ? 'Test User' : null;
  }
}

class MockMemberAvatarProvider extends Mock {
  Future<MemoryImage?> call(MemberInfo query) async {
    // Return a dummy image for 'test' user
    if (query.userId == 'test') {
      return MemoryImage(Uint8List(0)); // Empty byte array for demo
    }
    return null;
  }
}

class MockMemberAvatarInfoProvider extends Mock {
  AvatarInfo call(MemberInfo query) {
    // Return mocked AvatarInfo
    return AvatarInfo(
      uniqueId: query.userId,
      displayName: 'Test User', // Mocked display name
      avatar: NetworkImage(
        'https://acter.global/avatar.png',
      ), // Mocked avatar URL
    );
  }
}

void main() {
  late MockTask mockTask;
  late MockOnTapTaskItem mockOnTapTaskItem;
  late MockGoRouter mockedGoRouter;
  late MockNavigator navigator;
  late MockMemberDisplayNameProvider mockMemberDisplayNameProvider;
  late MockMemberAvatarProvider mockMemberAvatarProvider;
  late MockMemberAvatarInfoProvider mockMemberAvatarInfoProvider;

  setUp(() {
    mockTask = MockTask();
    mockOnTapTaskItem = MockOnTapTaskItem();
    mockedGoRouter = MockGoRouter();
    navigator = MockNavigator();
    when(navigator.canPop).thenReturn(true);
    when(() => navigator.pop(any())).thenAnswer((_) async {});
    when(() => navigator.push<void>(any())).thenAnswer((_) async {});
    // Create mock providers outside the function
    mockMemberDisplayNameProvider = MockMemberDisplayNameProvider();
    mockMemberAvatarProvider = MockMemberAvatarProvider();
    mockMemberAvatarInfoProvider = MockMemberAvatarInfoProvider();
  });

  Future<void> createWidgetUnderTest({
    required WidgetTester tester,
    final bool showBreadCrumb = false,
    required MockTask mockTask,
    required final Function onDone, // Make this non-nullable
    required final Function onTap,
  }) async {
    final mockedNotifier = MockTaskItemsNotifier(shouldFail: false);
    final fakeListNotifier = FakeTaskListItemNotifier(shouldFail: false);

    await tester.pumpProviderWidget(
      navigatorOverride: navigator,
      goRouter: mockedGoRouter,
      overrides: [
        // Mocking memberDisplayNameProvider, _memberAvatarProvider, and memberAvatarInfoProvider
        memberDisplayNameProvider.overrideWith((ref, query) {
          return mockMemberDisplayNameProvider.call(query);
        }),
        memberAvatarProvider.overrideWith((ref, query) {
          return mockMemberAvatarProvider.call(
            query,
          ); // This returns Future<MemoryImage?>
        }),
        memberAvatarInfoProvider.overrideWith((ref, query) {
          return mockMemberAvatarInfoProvider.call(
            query,
          ); // Returning mocked AvatarInfo
        }),
        taskItemProvider.overrideWith((ref, query) {
          return mockedNotifier.build(mockTask);
        }),
        taskListProvider.overrideWith(() => fakeListNotifier),
        roomDisplayNameProvider.overrideWith((a, b) => 'task'),
        roomMembershipProvider.overrideWith((a, b) => null),
      ],
      child: TaskItem(
        taskListId: mockTask.taskListIdStr(),
        taskId: mockTask.eventIdStr(),
        showBreadCrumb: showBreadCrumb,
        onDone: () {
          onDone();
        },
        onTap: () {
          onTap();
        },
      ),
    );
    // Wait for the async provider to load
    await tester.pump();
  }

  testWidgets('TaskItem renders with correct title', (tester) async {
    // Create the widget under test
    await createWidgetUnderTest(
      tester: tester,
      onDone: () {}, // Non-nullable callbacks
      onTap: () {},
      mockTask: mockTask,
    );

    // Pump and settle the widget
    await tester.pumpAndSettle();

    // Check if the widget's title is rendered correctly
    expect(find.text('Fake Task'), findsOneWidget);
  });

  testWidgets('TaskItem navigates to task details when tapped', (tester) async {
    // Arrange: Create the widget under test
    await createWidgetUnderTest(
      tester: tester,
      onDone: () {},
      onTap: (mockOnTapTaskItem..call('1234')).call,
      mockTask: mockTask,
    );
    await tester.tap(find.byType(ListTile));
    await tester
        .pumpAndSettle(); // Wait for any potential animations or rebuilds
    // Assert: Verify that the 'onTap' callback was called
    verify(() => mockOnTapTaskItem.call('1234')).called(1);
  });

  testWidgets('TaskItem triggers onTap callback when tapped', (tester) async {
    await createWidgetUnderTest(
      tester: tester,
      onDone: () {},
      onTap: (mockOnTapTaskItem..call('1234')).call,
      mockTask: mockTask,
    );

    // Act: Pump the widget and simulate a tap on the ListTile
    await tester.tap(find.byType(ListTile));
    await tester
        .pumpAndSettle(); // Wait for any potential animations or rebuilds

    // Assert: Verify that the 'onTap' callback was called
    verify(() => mockOnTapTaskItem.call('1234')).called(1);
  });

  testWidgets('TaskItem due date is present', (tester) async {
    final mockTaskDate = MockTask(date: '2025-01-10');
    await createWidgetUnderTest(
      tester: tester,
      onDone: () {},
      onTap: () {},
      mockTask: mockTaskDate,
    );
    await tester.pumpAndSettle();
    final date = DateTime.parse(mockTaskDate.date.toString());
    final dateText = DateFormat(DateFormat.YEAR_MONTH_WEEKDAY_DAY).format(date);
    final label =
        date.isToday
            ? 'Due today'
            : date.isTomorrow
            ? 'Due tomorrow'
            : date.isPast
            ? date.timeago()
            : dateText;
    expect(find.text(label), findsOneWidget);
    expect(find.byIcon(Icons.access_time), findsOneWidget);
  });

  testWidgets('TaskItem due date is not present', (tester) async {
    await createWidgetUnderTest(
      tester: tester,
      onDone: () {},
      onTap: () {},
      mockTask: mockTask,
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.access_time), findsNothing);
  });

  testWidgets('TaskItem handles showBreadCrumb when it false', (tester) async {
    final mockDescription = MockTask(desc: 'new desc');
    await createWidgetUnderTest(
      tester: tester,
      showBreadCrumb: false,
      onDone: () {},
      onTap: () {},
      mockTask: mockDescription,
    );

    await tester.pumpAndSettle();
    expect(
      find.byType(RoomAvatarBuilder),
      findsNothing,
    ); // Should not find room avatar widget
    expect(
      find.text('new desc'),
      findsOneWidget,
    ); // Should find Text with description
  });

  testWidgets('TaskItem handles task assignee', (tester) async {
    await createWidgetUnderTest(
      tester: tester,
      showBreadCrumb: false,
      onDone: () {},
      onTap: () {},
      mockTask: mockTask,
    );

    await tester.pumpAndSettle();
    expect(
      find.byType(ActerAvatar),
      findsOneWidget,
    ); // Should not find room avatar widget
  });
}
