import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/acter_search_widget.dart';
import 'package:acter/features/tasks/pages/tasks_list_page.dart';
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
}
