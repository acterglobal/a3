import 'package:acter/features/home/providers/task_providers.dart';
import 'package:acter/features/home/widgets/my_tasks.dart';
import 'package:acter/features/tasks/actions/my_task_actions.dart';
import 'package:acter/features/tasks/widgets/task_item.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../../helpers/mock_tasks_providers.dart';
import '../../helpers/test_util.dart';

class MockSortedTasks extends Mock implements SortedTasks {}

void main() {
  late MockSortedTasks mockSortedTasks;

  setUp(() {
    mockSortedTasks = MockSortedTasks();
    registerFallbackValue(TaskDueCategory.overdue);
    
    // Setup default mock behavior
    when(() => mockSortedTasks.totalCount).thenReturn(0);
    when(() => mockSortedTasks.hasTasksInCategory(any())).thenReturn(false);
    when(() => mockSortedTasks.overdue).thenReturn([]);
    when(() => mockSortedTasks.today).thenReturn([]);
    when(() => mockSortedTasks.tomorrow).thenReturn([]);
    when(() => mockSortedTasks.laterThisWeek).thenReturn([]);
    when(() => mockSortedTasks.later).thenReturn([]);
    when(() => mockSortedTasks.noDueDate).thenReturn([]);
  });

  Future<void> createWidgetUnderTest(WidgetTester tester) async {
    await tester.pumpProviderWidget(
      overrides: [
        sortedTasksProvider.overrideWith(
          (ref) => Future.value(mockSortedTasks),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: [
          L10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: L10n.supportedLocales,
        home: MyTasksSection(limit: 5),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows empty state when total count is 0',
      (WidgetTester tester) async {
    when(() => mockSortedTasks.totalCount).thenReturn(0);

    await createWidgetUnderTest(tester);

    expect(find.byType(MyTasksSection), findsOneWidget);
    expect(find.byType(TaskItem), findsNothing);
  });

  testWidgets('shows task items with dividers between them',
      (WidgetTester tester) async {
    final mockTasks = List.generate(3, (_) => MockTask());
    when(() => mockSortedTasks.totalCount).thenReturn(3);
    when(() => mockSortedTasks.hasTasksInCategory(any())).thenReturn(true);
    when(() => mockSortedTasks.today).thenReturn(mockTasks);

    await createWidgetUnderTest(tester);

    expect(find.byType(TaskItem), findsNWidgets(3));
    expect(find.byType(Divider), findsNWidgets(2)); // 3 items = 2 dividers
  });

  testWidgets('shows tasks from different categories in priority order',
      (WidgetTester tester) async {
    final overdueTask = MockTask();
    final todayTask = MockTask();
    final tomorrowTask = MockTask();
    
    when(() => mockSortedTasks.totalCount).thenReturn(3);
    when(() => mockSortedTasks.hasTasksInCategory(any())).thenReturn(true);
    when(() => mockSortedTasks.overdue).thenReturn([overdueTask]);
    when(() => mockSortedTasks.today).thenReturn([todayTask]);
    when(() => mockSortedTasks.tomorrow).thenReturn([tomorrowTask]);

    await createWidgetUnderTest(tester);

    expect(find.byType(TaskItem), findsNWidgets(3));
  });

  testWidgets('shows see all button in section header',
      (WidgetTester tester) async {
    final mockTask = MockTask();
    when(() => mockSortedTasks.totalCount).thenReturn(1);
    when(() => mockSortedTasks.hasTasksInCategory(any())).thenReturn(true);
    when(() => mockSortedTasks.today).thenReturn([mockTask]);

    await createWidgetUnderTest(tester);

    // Get the context and L10n instance
    final BuildContext context = tester.element(find.byType(MyTasksSection));
    final lang = L10n.of(context);

    expect(find.text(lang.seeAll), findsOneWidget);
  });

  testWidgets('shows more tasks button when total tasks exceed limit',
      (WidgetTester tester) async {
    final mockTasks = List.generate(10, (_) => MockTask());
    when(() => mockSortedTasks.totalCount).thenReturn(10);
    when(() => mockSortedTasks.hasTasksInCategory(any())).thenReturn(true);
    when(() => mockSortedTasks.today).thenReturn(mockTasks);

    await createWidgetUnderTest(tester);

    // Get the context and L10n instance
    final BuildContext context = tester.element(find.byType(MyTasksSection));
    final lang = L10n.of(context);

    expect(find.text(lang.countMoreTasks(5)), findsOneWidget);
  });

  testWidgets('respects task limit parameter',
      (WidgetTester tester) async {
    final mockTasks = List.generate(10, (_) => MockTask());
    when(() => mockSortedTasks.totalCount).thenReturn(10);
    when(() => mockSortedTasks.hasTasksInCategory(any())).thenReturn(true);
    when(() => mockSortedTasks.today).thenReturn(mockTasks);

    await tester.pumpProviderWidget(
      overrides: [
        sortedTasksProvider.overrideWith(
          (ref) => Future.value(mockSortedTasks),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: [
          L10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: L10n.supportedLocales,
        home: MyTasksSection(limit: 3),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TaskItem), findsNWidgets(3));
  });

  testWidgets('shows task items with breadcrumb',
      (WidgetTester tester) async {
    final mockTask = MockTask();
    when(() => mockSortedTasks.totalCount).thenReturn(1);
    when(() => mockSortedTasks.hasTasksInCategory(any())).thenReturn(true);
    when(() => mockSortedTasks.today).thenReturn([mockTask]);

    await createWidgetUnderTest(tester);

    final taskItem = tester.widget<TaskItem>(find.byType(TaskItem));
    expect(taskItem.showBreadCrumb, isTrue);
  });

  testWidgets('shows tasks from all categories when available',
      (WidgetTester tester) async {
    final overdueTask = MockTask();
    final todayTask = MockTask();
    final tomorrowTask = MockTask();
    final laterThisWeekTask = MockTask();
    final laterTask = MockTask();
    final noDueDateTask = MockTask();
    
    when(() => mockSortedTasks.totalCount).thenReturn(6);
    when(() => mockSortedTasks.hasTasksInCategory(any())).thenReturn(true);
    when(() => mockSortedTasks.overdue).thenReturn([overdueTask]);
    when(() => mockSortedTasks.today).thenReturn([todayTask]);
    when(() => mockSortedTasks.tomorrow).thenReturn([tomorrowTask]);
    when(() => mockSortedTasks.laterThisWeek).thenReturn([laterThisWeekTask]);
    when(() => mockSortedTasks.later).thenReturn([laterTask]);
    when(() => mockSortedTasks.noDueDate).thenReturn([noDueDateTask]);

    await createWidgetUnderTest(tester);

    expect(find.byType(TaskItem), findsNWidgets(5));
  });
}