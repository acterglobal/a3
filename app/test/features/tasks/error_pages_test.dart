import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/acter_search_widget.dart';
import 'package:acter/features/tasks/pages/task_item_detail_page.dart';
import 'package:acter/features/tasks/pages/task_list_details_page.dart';
import 'package:acter/features/tasks/pages/tasks_list_page.dart';
import 'package:acter/features/tasks/providers/task_items_providers.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/error_helpers.dart';
import '../../helpers/mock_tasks_providers.dart';
import '../../helpers/test_util.dart';

void main() {
  group('TaskList List Error Pages', () {
    testWidgets('full list', (tester) async {
      final mockedTaskListNotifier = MockAsyncAllTaskListsNotifier();
      await tester.pumpProviderWidget(
        overrides: [
          allTasksListsProvider.overrideWith(() => mockedTaskListNotifier),
          hasSpaceWithPermissionProvider.overrideWith((_, ref) => false),
        ],
        child: const TasksListPage(),
      );
      await tester.ensureErrorPageWithRetryWorks();
    });
    testWidgets('full list with search', (tester) async {
      final mockedTaskListNotifier = MockAsyncAllTaskListsNotifier();

      await tester.pumpProviderWidget(
        overrides: [
          searchValueProvider
              .overrideWith((_) => 'some string'), // set a search string
          allTasksListsProvider.overrideWith(() => mockedTaskListNotifier),
          hasSpaceWithPermissionProvider.overrideWith((_, ref) => false),
        ],
        child: const TasksListPage(),
      );
      await tester.ensureErrorPageWithRetryWorks();
    });

    testWidgets('space list', (tester) async {
      final mockedTaskListNotifier = MockAsyncAllTaskListsNotifier();
      await tester.pumpProviderWidget(
        overrides: [
          roomDisplayNameProvider.overrideWith((a, b) => 'test'),
          allTasksListsProvider.overrideWith(() => mockedTaskListNotifier),
          hasSpaceWithPermissionProvider.overrideWith((_, ref) => false),
        ],
        child: const TasksListPage(
          spaceId: '!test',
        ),
      );
      await tester.ensureErrorPageWithRetryWorks();
    });

    testWidgets('space list with search', (tester) async {
      final mockedTaskListNotifier = MockAsyncAllTaskListsNotifier();
      await tester.pumpProviderWidget(
        overrides: [
          roomDisplayNameProvider.overrideWith((a, b) => 'test'),
          searchValueProvider
              .overrideWith((_) => 'some search'), // set a search string
          allTasksListsProvider.overrideWith(() => mockedTaskListNotifier),
          hasSpaceWithPermissionProvider.overrideWith((_, ref) => false),
        ],
        child: const TasksListPage(
          spaceId: '!test',
        ),
      );
      await tester.ensureErrorPageWithRetryWorks();
    });
  });
  group('TaskList Details Error Pages', () {
    testWidgets('body error page', (tester) async {
      final mockedNotifier = MockTaskListItemNotifier();
      await tester.pumpProviderWidget(
        overrides: [
          taskListItemProvider.overrideWith(() => mockedNotifier),
          hasSpaceWithPermissionProvider.overrideWith((_, ref) => false),
        ],
        child: const TaskListDetailPage(taskListId: 'taskListId'),
      );
      await tester.ensureErrorPageWithRetryWorks();
    });
  });
  group('Task Details Error Pages', () {
    testWidgets('body error page', (tester) async {
      final mockedNotifier = MockTaskListItemNotifier(shouldFail: false);
      await tester.pumpProviderWidget(
        overrides: [
          notifierTaskProvider.overrideWith(() => MockTaskItemNotifier()),
          taskListItemProvider.overrideWith(() => mockedNotifier),
          hasSpaceWithPermissionProvider.overrideWith((_, ref) => false),
        ],
        child: const TaskItemDetailPage(
          taskListId: 'taskListId',
          taskId: 'taskid',
        ),
      );
      await tester.ensureErrorPageWithRetryWorks();
    });
  });
}
