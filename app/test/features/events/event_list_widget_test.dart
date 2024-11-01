import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:acter/features/datetime/providers/utc_now_provider.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/providers/event_type_provider.dart';
import 'package:acter/features/events/widgets/event_list_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockingjay/mockingjay.dart';
import '../../helpers/error_helpers.dart';
import '../../helpers/mock_event_providers.dart';
import '../../helpers/test_util.dart';

void main() {
  group('Event List', () {
    testWidgets('displays empty state when there are no events',
        (tester) async {
      //Arrange:
      const emptyState = Text('empty state');

      // Build the widget tree with the mocked provider
      await tester.pumpProviderWidget(
        overrides: [
          eventListSearchFilterProvider
              .overrideWith((ref, manager) async => []),
        ],
        child: const EventListWidget(emptyState: emptyState),
      );

      // Act
      await tester.pumpAndSettle(); // Allow the widget to settle

      // Assert
      expect(
        find.text('empty state'),
        findsOneWidget,
      ); // Ensure the empty state widget is displayed
    });

    testWidgets(
        'displays error state when there is issue in loading event list',
        (tester) async {
      bool shouldFail = true;

      // Build the widget tree with the mocked provider
      await tester.pumpProviderWidget(
        overrides: [
          eventListSearchFilterProvider.overrideWith((ref, manager) async {
            if (shouldFail) {
              shouldFail = false;
              throw 'Some Error';
            } else {
              return [];
            }
          }),
        ],
        child: const EventListWidget(),
      );
      await tester.ensureErrorPageWithRetryWorks();
    });

    testWidgets('displays list of event when data is available',
        (tester) async {
      // Arrange

      const eventFilter = EventFilters.upcoming;
      final mockedNotifier = MockAsyncCalendarEventNotifier();
      final mockUtcNowNotifier = MockUtcNowNotifier();
      final mockAsyncRsvpStatusNotifier = MockAsyncRsvpStatusNotifier();

      final mockEvent1 = MockEvent(fakeEventTitle: 'Fake Event1');
      final mockEvent2 = MockEvent(fakeEventTitle: 'Fake Event2');
      final mockEvent3 = MockEvent(fakeEventTitle: 'Fake Event3');

      // Build the widget tree with the mocked provider
      await tester.pumpProviderWidget(
        overrides: [
          utcNowProvider.overrideWith((ref) => mockUtcNowNotifier),
          eventTypeProvider.overrideWith((ref, event) => eventFilter),
          calendarEventProvider.overrideWith(() => mockedNotifier),
          myRsvpStatusProvider.overrideWith(() => mockAsyncRsvpStatusNotifier),
          roomMembershipProvider.overrideWith((a, b) => null),
          isBookmarkedProvider.overrideWith((a, b) => false),
          roomDisplayNameProvider.overrideWith((a, b) => 'test'),
          bookmarkedEventListProvider.overrideWith((ref, spaceId) => []),
          allEventListProvider.overrideWith(() => any()),
          allOngoingEventListProvider.overrideWith((ref, spaceId) => []),
          allUpcomingEventListProvider.overrideWith((ref, spaceId) => []),
          allPastEventListProvider.overrideWith((ref, spaceId) => []),
          eventListSearchFilterProvider.overrideWith(
            (ref, manager) async => [
              mockEvent1,
              mockEvent2,
              mockEvent3,
            ],
          ),
        ],
        child: const EventListWidget(),
      );
      // Act
      await tester.pumpAndSettle(); // Allow the widget to settle

      // Assert
      expect(
        find.text('Fake Event1'),
        findsOne,
      );
      expect(
        find.text('Fake Event2'),
        findsOne,
      );
      expect(
        find.text('Fake Event3'),
        findsOne,
      );
    });
  });
}
