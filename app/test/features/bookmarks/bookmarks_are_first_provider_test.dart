import 'package:acter/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:acter/features/bookmarks/types.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/mock_pins_providers.dart';
import '../../helpers/mock_tasks_providers.dart';

void main() {
  group('Bookmarks are first', () {
    test('Pins', () async {
      final mockedPinsList = [
        FakeActerPin(eventId: 'a'),
        FakeActerPin(eventId: 'b'),
        FakeActerPin(eventId: '1'),
        FakeActerPin(eventId: '2'),
        FakeActerPin(eventId: 'c'),
      ];

      List<String> bookmarksLists = ['2', '1', '3'];
      final container = ProviderContainer(
        overrides: [
          pinListProvider.overrideWith((r, a) => mockedPinsList),
          bookmarkByTypeProvider.overrideWith(
            (a, b) => (b == BookmarkType.pins) ? bookmarksLists : [],
          ),
        ],
      );

      final pins = await container.read(pinsProvider(null).future);
      // check if they were reordered correctly
      expect(pins.map((e) => e.eventIdStr()), ['2', '1', 'a', 'b', 'c']);
      // let's update
      bookmarksLists = ['1', '4'];
      container.refresh(bookmarkByTypeProvider(BookmarkType.pins));

      final newPins = await container.read(pinsProvider(null).future);
      // check if they were reordered correctly
      expect(newPins.map((e) => e.eventIdStr()), ['1', 'a', 'b', '2', 'c']);
    });

    test('TaskList', () async {
      final mockedTaskLists = SimpleReturningTasklists([
        FakeTaskList(eventId: 'a'),
        FakeTaskList(eventId: 'b'),
        FakeTaskList(eventId: '1'),
        FakeTaskList(eventId: '2'),
        FakeTaskList(eventId: 'c'),
      ]);

      List<String> bookmarksLists = ['4', '2', '1', '3'];

      final container = ProviderContainer(
        overrides: [
          allTasksListsProvider.overrideWith(() => mockedTaskLists),
          bookmarkByTypeProvider.overrideWith(
            (a, b) => (b == BookmarkType.task_lists) ? bookmarksLists : [],
          ),
        ],
      );

      final taskLists = await container.read(taskListsProvider(null).future);
      // check if they were reordered correctly
      expect(taskLists, ['2', '1', 'a', 'b', 'c']);
      // let's update
      bookmarksLists = ['1'];
      container.refresh(bookmarkByTypeProvider(BookmarkType.task_lists));

      final newTaskLists = await container.read(taskListsProvider(null).future);
      // check if they were reordered correctly
      expect(newTaskLists, ['1', 'a', 'b', '2', 'c']);
    });
  });
}
