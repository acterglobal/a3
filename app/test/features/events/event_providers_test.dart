import 'package:acter/features/datetime/providers/utc_now_provider.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/providers/notifiers/rsvp_notifier.dart';
import 'package:acter/features/search/providers/quick_search_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_event_providers.dart';

// Create a mock for EventListNotifier
class MockEventListNotifier extends AsyncNotifier<List<CalendarEvent>>
    with Mock {
  final List<CalendarEvent> events;

  MockEventListNotifier(this.events);

  @override
  Future<List<CalendarEvent>> build() async => events;
}

// Mock class for RsvpStatusNotifier
class CustomMockRsvpStatusNotifier extends AsyncRsvpStatusNotifier {
  @override
  Future<RsvpStatusTag?> build(String arg) async {
    // Mock RSVP behavior: "Yes" for events 1, 3, 5
    // "No" for event 2, "Maybe" for event 4
    switch (arg) {
      case 'eventId': // Default ID for mock events
        return RsvpStatusTag.Yes;
      default:
        final eventNumber = int.tryParse(arg.split(' ').last);
        if (eventNumber != null) {
          if (eventNumber == 1 ||
              eventNumber == 2 ||
              eventNumber == 3 ||
              eventNumber == 5) {
            return RsvpStatusTag.Yes;
          } else if (eventNumber == 4) {
            return RsvpStatusTag.Maybe;
          }
        }
        return null;
    }
  }
}

// Create mock events with different timestamps for testing order
MockEvent createMockEventWithTimestamp(String title, int timestamp) =>
    MockEvent(
      fakeEventTitle: title,
      fakeEventId: title,
      fakeEventTs: timestamp,
    );

void main() {
  late ProviderContainer container;
  late List<CalendarEvent> mockEvents;
  const String testSpaceId = 'space123';

  setUp(() {
    // Create mock events with timestamps in descending order
    // (newer events first in the original list)
    mockEvents = [
      createMockEventWithTimestamp('Event 1', 1000), // newest
      createMockEventWithTimestamp('Event 2', 900),
      createMockEventWithTimestamp('Event 3', 800),
      createMockEventWithTimestamp('Event 4', 700),
      createMockEventWithTimestamp('Event 5', 600), // oldest
    ];

    // Register fallback values
    registerFallbackValue(MockEvent());

    container = ProviderContainer(
      overrides: [
        // Override the event type provider to map events to different types based on their timestamp
        utcNowProvider.overrideWith(
          (ref) => MockUtcNowNotifier(ts: 901),
        ), //901 is not
        // Override the allEventListProvider to return our mock events
        allEventListProvider.overrideWith((ref, spaceId) async => mockEvents),

        // Mock the myRsvpStatusProvider for testing "my" events
        myRsvpStatusProvider.overrideWith(() => CustomMockRsvpStatusNotifier()),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  // Tests for allPastEventListProvider and allPastEventListWithSearchProvider
  group('allPastEventListProvider tests', () {
    test('should sort past events in descending order by time', () async {
      // Act
      final result = await container.read(
        allPastEventListProvider(testSpaceId).future,
      );
      // Assert
      expect(result.length, equals(3)); // everything under 900 is past
      expect(result[0].title(), equals('Event 3'));
      expect(result[1].title(), equals('Event 4'));
      expect(result[2].title(), equals('Event 5'));
    });
  });

  group('allPastEventListWithSearchProvider tests', () {
    test('should filter events by search term and maintain order', () async {
      // Arrange - set search term
      container.read(eventListSearchTermProvider(testSpaceId).notifier).state =
          '5';

      // Act
      final result = await container.read(
        allPastEventListWithSearchProvider(testSpaceId).future,
      );

      // Assert
      expect(result.length, equals(1));
      expect(result[0].title(), equals('Event 5'));
    });

    test('empty search term should return all past events in order', () async {
      // Arrange - set empty search term
      container.read(eventListSearchTermProvider(testSpaceId).notifier).state =
          '';

      // Act
      final result = await container.read(
        allPastEventListWithSearchProvider(testSpaceId).future,
      );

      // Assert
      expect(result.length, equals(3)); // Everythign under 900 is past
      expect(result[0].title(), equals('Event 3'));
      expect(result[1].title(), equals('Event 4'));
      expect(result[2].title(), equals('Event 5'));
    });
  });

  // Tests for ongoing events providers
  group('allOngoingEventListProvider tests', () {
    test('should return only ongoing events', () async {
      // Act
      final result = await container.read(
        allOngoingEventListProvider(testSpaceId).future,
      );
      // Assert
      expect(
        result.length,
        equals(1),
      ); // Only Event 2 is classified as "ongoing"
      expect(result[0].title(), equals('Event 2'));
    });
    testWidgets(
      'should return only ongoing events when moving forward in time',
      (tester) async {
        // Act
        final result = await container.read(
          allOngoingEventListProvider(testSpaceId).future,
        );

        // Assert
        expect(
          result.length,
          equals(1),
        ); // Only Event 2 is classified as "ongoing"
        expect(result[0].title(), equals('Event 2'));

        container
            .read(utcNowProvider.notifier)
            .state = DateTime.fromMillisecondsSinceEpoch(1001);

        // Act
        final newResult = await container.read(
          allOngoingEventListProvider(testSpaceId).future,
        );

        // Assert
        expect(newResult.length, equals(1));
        expect(newResult[0].title(), equals('Event 1'));

        // nothing anymore

        container
            .read(utcNowProvider.notifier)
            .state = DateTime.fromMillisecondsSinceEpoch(2001);

        // Act
        final nothing = await container.read(
          allOngoingEventListProvider(testSpaceId).future,
        );

        // Assert
        expect(nothing.length, equals(0));
        await tester.pumpAndSettle(); // clear timers
      },
    );
  });

  group('allOngoingEventListWithSearchProvider tests', () {
    test('should filter ongoing events by search term', () async {
      // Arrange - set search term
      container.read(eventListSearchTermProvider(testSpaceId).notifier).state =
          '2';

      // Act
      final result = await container.read(
        allOngoingEventListWithSearchProvider(testSpaceId).future,
      );

      // Assert
      expect(result.length, equals(1));
      expect(result[0].title(), equals('Event 2'));
    });

    testWidgets('search term with no matches should return empty list', (
      tester,
    ) async {
      // Arrange - set search term with no matches
      container.read(eventListSearchTermProvider(testSpaceId).notifier).state =
          'NoMatch';

      // Act
      final result = await container.read(
        allOngoingEventListWithSearchProvider(testSpaceId).future,
      );

      // Assert
      expect(result.length, equals(0));
      await tester.pumpAndSettle(); // clear timers
    });

    testWidgets('search term updates properly', (tester) async {
      // Arrange - set search term with no matches
      container.read(eventListSearchTermProvider(testSpaceId).notifier).state =
          'NoMatch';

      // Act
      final result = await container.read(
        allOngoingEventListWithSearchProvider(testSpaceId).future,
      );

      // Assert
      expect(result.length, equals(0));

      container.read(eventListSearchTermProvider(testSpaceId).notifier).state =
          'Event';

      // Act
      final results = await container.read(
        allOngoingEventListWithSearchProvider(testSpaceId).future,
      );

      // Assert
      expect(results.length, equals(1));
      await tester.pumpAndSettle(); // clear timers
    });

    testWidgets(
      'should return only ongoing events when moving forward in time',
      (tester) async {
        // Act
        final result = await container.read(
          allOngoingEventListWithSearchProvider(testSpaceId).future,
        );

        // Assert
        expect(
          result.length,
          equals(1),
        ); // Only Event 2 is classified as "ongoing"
        expect(result[0].title(), equals('Event 2'));

        container
            .read(utcNowProvider.notifier)
            .state = DateTime.fromMillisecondsSinceEpoch(1001);

        // Act
        final newResult = await container.read(
          allOngoingEventListProvider(testSpaceId).future,
        );

        // Assert
        expect(newResult.length, equals(1));
        expect(newResult[0].title(), equals('Event 1'));

        // nothing anymore

        container
            .read(utcNowProvider.notifier)
            .state = DateTime.fromMillisecondsSinceEpoch(2001);

        // Act
        final nothing = await container.read(
          allOngoingEventListProvider(testSpaceId).future,
        );

        // Assert
        expect(nothing.length, equals(0));

        await tester.pumpAndSettle(); // clear timers
      },
    );
  });

  // Tests for upcoming events providers
  group('allUpcomingEventListProvider tests', () {
    test('should return only upcoming events in ascending order', () async {
      // Act
      final result = await container.read(
        allUpcomingEventListProvider(testSpaceId).future,
      );

      // Assert
      expect(result.length, equals(1)); // Events 1 "upcoming"
      // Should be sorted in ascending order
      expect(result[0].title(), equals('Event 1')); // timestamp: 1000
    });

    testWidgets('updates when the time is updated', (tester) async {
      // Act
      final result = await container.read(
        allUpcomingEventListProvider(testSpaceId).future,
      );

      // Assert
      expect(result.length, equals(1)); // Events 1 "upcoming"
      // Should be sorted in ascending order
      expect(result[0].title(), equals('Event 1')); // timestamp: 1000

      container
          .read(utcNowProvider.notifier)
          .state = DateTime.fromMillisecondsSinceEpoch(750);

      await tester.pump(const Duration(milliseconds: 100));

      // Act
      final newResult = await container.read(
        allUpcomingEventListProvider(testSpaceId).future,
      );

      // Assert
      expect(newResult.length, equals(3)); // Events 1, 2, 3 "upcoming"
      // Should be sorted in ascending order of soonest to latest
      expect(newResult[0].title(), equals('Event 3')); // timestamp: 1000
      expect(newResult[1].title(), equals('Event 2')); // timestamp: 900
      expect(newResult[2].title(), equals('Event 1')); // timestamp: 800
      await tester.pumpAndSettle(); // clear timers
    });
  });

  group('allUpcomingEventListWithSearchProvider tests', () {
    test('should filter upcoming events by search term', () async {
      // Arrange - set search term
      container.read(eventListSearchTermProvider(testSpaceId).notifier).state =
          '1';

      // Act
      final result = await container.read(
        allUpcomingEventListWithSearchProvider(testSpaceId).future,
      );

      // Assert
      expect(result.length, equals(1));
      expect(result[0].title(), equals('Event 1'));
    });
  });

  // Tests for "my" events providers
  group('myOngoingEventListProvider tests', () {
    test('should return only ongoing events I have RSVP\'d Yes to', () async {
      // Act
      final result = await container.read(
        myOngoingEventListProvider(testSpaceId).future,
      );

      // Assert
      expect(result.length, equals(1)); // Event 1 is ongoing and RSVP'ed Yes
      expect(result[0].title(), equals('Event 2'));
    });
  });

  group('myUpcomingEventListProvider tests', () {
    test('should return only upcoming events I have RSVP\'d Yes to', () async {
      // Act
      final result = await container.read(
        myUpcomingEventListProvider(testSpaceId).future,
      );

      // Assert
      expect(
        result.length,
        equals(1),
      ); // Only Event 3 is upcoming and RSVP'ed Yes
      expect(result[0].title(), equals('Event 1'));
    });
  });

  group('myPastEventListProvider tests', () {
    test('should return only past events I have RSVP\'d Yes to', () async {
      // Act
      final result = await container.read(
        myPastEventListProvider(testSpaceId).future,
      );

      // Assert
      expect(result.length, equals(2));
      expect(result[0].title(), equals('Event 3'));
      expect(result[1].title(), equals('Event 5'));
    });
  });

  // Tests for allEventSorted provider
  group('allEventSorted provider tests', () {
    test(
      'should return all events sorted by ongoing, upcoming, then past',
      () async {
        // Act
        final result = await container.read(allEventSorted(testSpaceId).future);

        // Assert
        expect(result.length, equals(5));
        // Should be sorted in this order: ongoing, upcoming, past
        expect(result[0].title(), equals('Event 2')); // ongoing
        expect(result[1].title(), equals('Event 1')); // upcomoing
        // upcoming events 2, 3, 4 in ascending order
        expect(result[2].title(), equals('Event 3'));
        expect(result[3].title(), equals('Event 4'));
        expect(result[4].title(), equals('Event 5')); // past
      },
    );
  });

  // Tests for quick search provider
  group('eventListQuickSearchedProvider tests', () {
    test('should find events matching the quick search term', () async {
      // Arrange
      container.read(quickSearchValueProvider.notifier).state = 'Event 2';

      // Act
      final result = await container.read(
        eventListQuickSearchedProvider.future,
      );

      // Assert
      expect(result.length, equals(1));
      expect(result[0].title(), equals('Event 2'));
    });
  });
}
