import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/bookmarks/providers/bookmarks_provider.dart';
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
      bool shouldFail = true;
      await tester.pumpProviderWidget(
        overrides: [
          tasksListSearchProvider.overrideWith((ref, spaceId) {
            if (shouldFail) {
              // toggle failure so the retry works
              shouldFail = !shouldFail;
              throw 'Expected fail: Task not loaded';
            }
            return [];
          }),
          bookmarkByTypeProvider.overrideWith((a, ref) => []),
          hasSpaceWithPermissionProvider.overrideWith((_, ref) => false),
        ],
        child: const TasksListPage(),
      );
      await tester.ensureErrorPageWithRetryWorks();
    });
    testWidgets('full list with search', (tester) async {
      bool shouldFail = true;

      await tester.pumpProviderWidget(
        overrides: [
          tasksListSearchProvider.overrideWith((ref, spaceId) {
            if (shouldFail) {
              // toggle failure so the retry works
              shouldFail = !shouldFail;
              throw 'Expected fail: Task not loaded';
            }
            return [];
          }),
          bookmarkByTypeProvider.overrideWith((a, ref) => []),
          hasSpaceWithPermissionProvider.overrideWith((_, ref) => false),
        ],
        child: const TasksListPage(),
      );
      await tester.ensureErrorPageWithRetryWorks();
    });

    testWidgets('space list', (tester) async {
      bool shouldFail = true;
      await tester.pumpProviderWidget(
        overrides: [
          roomDisplayNameProvider.overrideWith((a, b) => 'test'),
          roomMembershipProvider.overrideWith((a, b) => null),
          tasksListSearchProvider.overrideWith((ref, spaceId) {
            if (shouldFail) {
              // toggle failure so the retry works
              shouldFail = !shouldFail;
              throw 'Expected fail: Task not loaded';
            }
            return [];
          }),
          bookmarkByTypeProvider.overrideWith((a, ref) => []),
          hasSpaceWithPermissionProvider.overrideWith((_, ref) => false),
        ],
        child: const TasksListPage(
          spaceId: '!test',
        ),
      );
      await tester.ensureErrorPageWithRetryWorks();
    });

    testWidgets('space list with search', (tester) async {
      bool shouldFail = true;
      await tester.pumpProviderWidget(
        overrides: [
          roomDisplayNameProvider.overrideWith((a, b) => 'test'),
          roomMembershipProvider.overrideWith((a, b) => null),
          tasksListSearchProvider.overrideWith((ref, spaceId) {
            if (shouldFail) {
              // toggle failure so the retry works
              shouldFail = !shouldFail;
              throw 'Expected fail: Task not loaded';
            }
            return [];
          }),
          bookmarkByTypeProvider.overrideWith((a, ref) => []),
          hasSpaceWithPermissionProvider.overrideWith((_, ref) => false),
        ],
        child: const TasksListPage(spaceId: '!test'),
      );
      await tester.ensureErrorPageWithRetryWorks();
    });
  });
  group('TaskList Details Error Pages', () {
    testWidgets('body error page', (tester) async {
      final mockedNotifier = FakeTaskListItemNotifier();
      await tester.pumpProviderWidget(
        overrides: [
          taskListProvider.overrideWith(() => mockedNotifier),
          hasSpaceWithPermissionProvider.overrideWith((_, ref) => false),
          roomMembershipProvider.overrideWith((a, b) => null),
          roomDisplayNameProvider.overrideWith((a, b) async => 'Space'),
          isBookmarkedProvider.overrideWith((a, ref) => false),
        ],
        child: const TaskListDetailPage(taskListId: 'taskListId'),
      );
      await tester.ensureErrorPageWithRetryWorks();
    });
  });
  group('Task Details Error Pages', () {
    testWidgets('body error page', (tester) async {
      final mockedNotifier = FakeTaskListItemNotifier(shouldFail: false);
      await tester.pumpProviderWidget(
        overrides: [
          notifierTaskProvider.overrideWith(() => MockTaskItemNotifier()),
          taskListProvider.overrideWith(() => mockedNotifier),
          hasSpaceWithPermissionProvider.overrideWith((_, ref) => false),
          roomDisplayNameProvider.overrideWith((a, b) async => 'Space'),
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
