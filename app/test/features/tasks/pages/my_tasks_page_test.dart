import 'package:acter/features/home/providers/task_providers.dart';
import 'package:acter/features/tasks/actions/my_task_actions.dart';
import 'package:acter/features/tasks/pages/my_tasks_page.dart';
import 'package:acter/features/tasks/widgets/task_item.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../../helpers/mock_tasks_providers.dart';
import '../../../helpers/test_util.dart';

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
        home: MyTasksPage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows no tasks message when there are no tasks',
      (WidgetTester tester) async {
    when(() => mockSortedTasks.totalCount).thenReturn(0);

    await createWidgetUnderTest(tester);

    // Get the context and L10n instance
    final BuildContext context = tester.element(find.byType(MyTasksPage));
    final lang = L10n.of(context);

    expect(find.text(lang.noTasks), findsOneWidget);
  });

  testWidgets('shows app bar with correct title',
      (WidgetTester tester) async {
    final mockTask = MockTask();
    when(() => mockSortedTasks.totalCount).thenReturn(1);
    when(() => mockSortedTasks.hasTasksInCategory(any())).thenReturn(true);
    when(() => mockSortedTasks.today).thenReturn([mockTask]);

    await createWidgetUnderTest(tester);

    // Get the context and L10n instance
    final BuildContext context = tester.element(find.byType(MyTasksPage));
    final lang = L10n.of(context);

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text(lang.myTasks), findsOneWidget);
  });

  testWidgets('shows overdue tasks section with correct icon and color',
      (WidgetTester tester) async {
    final mockTask = MockTask();
    when(() => mockSortedTasks.totalCount).thenReturn(1);
    when(() => mockSortedTasks.hasTasksInCategory(any())).thenReturn(true);
    when(() => mockSortedTasks.overdue).thenReturn([mockTask]);

    await createWidgetUnderTest(tester);

    // Get the context and L10n instance
    final BuildContext context = tester.element(find.byType(MyTasksPage));
    final lang = L10n.of(context);

    expect(find.text(lang.overdue), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(find.byType(TaskItem), findsOneWidget);
  });

  testWidgets('shows today tasks section with correct icon',
      (WidgetTester tester) async {
    final mockTask = MockTask();
    when(() => mockSortedTasks.totalCount).thenReturn(1);
    when(() => mockSortedTasks.hasTasksInCategory(any())).thenReturn(true);
    when(() => mockSortedTasks.today).thenReturn([mockTask]);

    await createWidgetUnderTest(tester);

    // Get the context and L10n instance
    final BuildContext context = tester.element(find.byType(MyTasksPage));
    final lang = L10n.of(context);

    expect(find.text(lang.today), findsOneWidget);
    expect(find.byIcon(Icons.today_rounded), findsOneWidget);
    expect(find.byType(TaskItem), findsOneWidget);
  });

  testWidgets('shows tomorrow tasks section with correct icon',
      (WidgetTester tester) async {
    final mockTask = MockTask();
    when(() => mockSortedTasks.totalCount).thenReturn(1);
    when(() => mockSortedTasks.hasTasksInCategory(any())).thenReturn(true);
    when(() => mockSortedTasks.tomorrow).thenReturn([mockTask]);

    await createWidgetUnderTest(tester);

    // Get the context and L10n instance
    final BuildContext context = tester.element(find.byType(MyTasksPage));
    final lang = L10n.of(context);

    expect(find.text(lang.tomorrow), findsOneWidget);
    expect(find.byIcon(Icons.event_rounded), findsOneWidget);
    expect(find.byType(TaskItem), findsOneWidget);
  });

  testWidgets('shows later this week tasks section with correct icon',
      (WidgetTester tester) async {
    final mockTask = MockTask();
    when(() => mockSortedTasks.totalCount).thenReturn(1);
    when(() => mockSortedTasks.hasTasksInCategory(any())).thenReturn(true);
    when(() => mockSortedTasks.laterThisWeek).thenReturn([mockTask]);

    await createWidgetUnderTest(tester);

    // Get the context and L10n instance
    final BuildContext context = tester.element(find.byType(MyTasksPage));
    final lang = L10n.of(context);

    expect(find.text(lang.laterThisWeek), findsOneWidget);
    expect(find.byIcon(Icons.calendar_month_rounded), findsOneWidget);
    expect(find.byType(TaskItem), findsOneWidget);
  });

  testWidgets('shows later tasks section with correct icon',
      (WidgetTester tester) async {
    final mockTask = MockTask();
    when(() => mockSortedTasks.totalCount).thenReturn(1);
    when(() => mockSortedTasks.hasTasksInCategory(any())).thenReturn(true);
    when(() => mockSortedTasks.later).thenReturn([mockTask]);

    await createWidgetUnderTest(tester);

    // Get the context and L10n instance
    final BuildContext context = tester.element(find.byType(MyTasksPage));
    final lang = L10n.of(context);

    expect(find.text(lang.later), findsOneWidget);
    expect(find.byIcon(Icons.event_note_rounded), findsOneWidget);
    expect(find.byType(TaskItem), findsOneWidget);
  });

  testWidgets('shows no due date tasks section with correct icon',
      (WidgetTester tester) async {
    final mockTask = MockTask();
    when(() => mockSortedTasks.totalCount).thenReturn(1);
    when(() => mockSortedTasks.hasTasksInCategory(any())).thenReturn(true);
    when(() => mockSortedTasks.noDueDate).thenReturn([mockTask]);

    await createWidgetUnderTest(tester);

    // Get the context and L10n instance
    final BuildContext context = tester.element(find.byType(MyTasksPage));
    final lang = L10n.of(context);

    expect(find.text(lang.noDueDate), findsOneWidget);
    expect(find.byIcon(Icons.event_busy_rounded), findsOneWidget);
    expect(find.byType(TaskItem), findsOneWidget);
  });

  testWidgets('shows multiple task sections with dividers',
      (WidgetTester tester) async {
    final mockTasks = List.generate(3, (_) => MockTask());
    when(() => mockSortedTasks.totalCount).thenReturn(3);
    when(() => mockSortedTasks.hasTasksInCategory(any())).thenReturn(true);
    when(() => mockSortedTasks.today).thenReturn(mockTasks);

    await createWidgetUnderTest(tester);

    expect(find.byType(TaskItem), findsNWidgets(3));
    expect(find.byType(Divider), findsNWidgets(2)); // 3 items = 2 dividers
  });

  testWidgets('shows all task sections when tasks are in all categories',
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

    // Get the context and L10n instance
    final BuildContext context = tester.element(find.byType(MyTasksPage));
    final lang = L10n.of(context);

    expect(find.text(lang.overdue), findsOneWidget);
    expect(find.text(lang.today), findsOneWidget);
    expect(find.text(lang.tomorrow), findsOneWidget);
    expect(find.text(lang.laterThisWeek), findsOneWidget);
    expect(find.text(lang.later), findsOneWidget);
    expect(find.byType(TaskItem), findsNWidgets(5));
  });

  testWidgets('shows sections in correct order',
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

    // Get the context and L10n instance
    final BuildContext context = tester.element(find.byType(MyTasksPage));
    final lang = L10n.of(context);
    
    final widgets = tester.widgetList(find.byType(Text)).toList();
    final sectionTitles = widgets.map((w) => (w as Text).data).toList();
    
    expect(sectionTitles.indexOf(lang.overdue), lessThan(sectionTitles.indexOf(lang.today)));
    expect(sectionTitles.indexOf(lang.today), lessThan(sectionTitles.indexOf(lang.tomorrow)));
  });
}