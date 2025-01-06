import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:acter/features/datetime/providers/utc_now_provider.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/providers/event_type_provider.dart';
import 'package:acter/features/events/widgets/event_item.dart';
import 'package:acter/features/events/widgets/event_list_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      final provider = FutureProvider<List<CalendarEvent>>((ref) async => []);

      // Build the widget tree with an empty provider
      await tester.pumpProviderWidget(
        child: EventListWidget(
          listProvider: provider,
          emptyStateBuilder: () => emptyState,
        ),
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

      final provider = FutureProvider<List<CalendarEvent>>((ref) async {
        if (shouldFail) {
          shouldFail = false;
          throw 'Some Error';
        } else {
          return [];
        }
      });

      // Build the widget tree with the mocked provider
      await tester.pumpProviderWidget(
        child: EventListWidget(
          listProvider: provider,
        ),
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

      final finalListProvider = FutureProvider<List<CalendarEvent>>(
        (ref) async => [
          mockEvent1,
          mockEvent2,
          mockEvent3,
        ],
      );

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
          allEventListProvider.overrideWith((ref, spaceId) => any()),
          allOngoingEventListProvider.overrideWith((ref, spaceId) => []),
          allUpcomingEventListProvider.overrideWith((ref, spaceId) => []),
          allPastEventListProvider.overrideWith((ref, spaceId) => []),
        ],
        child: EventListWidget(
          listProvider: finalListProvider,
        ),
      );
      // Initial build
      await tester.pump();

      // Wait for async operations
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.byType(EventItem),
        findsNWidgets(3),
        reason: 'Should find 3 EventItem widgets',
      );
    });
  });
}
