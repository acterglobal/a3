import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/providers/event_type_provider.dart';
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

// Create mock events with different timestamps for testing order
MockEvent createMockEventWithTimestamp(String title, int timestamp) =>
    MockEvent(fakeEventTitle: title, fakeEventTs: timestamp);

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
        // Override the event type provider to classify events as past
        eventTypeProvider.overrideWith((ref, event) => EventFilters.past),

        // Override the allEventListProvider to return our mock events
        allEventListProvider.overrideWith((ref, spaceId) async => mockEvents),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('allPastEventListProvider tests', () {
    test('should sort past events in descending order by time', () async {
      // Act
      final result = await container.read(
        allPastEventListProvider(testSpaceId).future,
      );

      // Assert
      expect(result.length, equals(5));
      expect(result[0].title(), equals('Event 1')); // newest first
      expect(result[1].title(), equals('Event 2'));
      expect(result[2].title(), equals('Event 3'));
      expect(result[3].title(), equals('Event 4'));
      expect(result[4].title(), equals('Event 5')); // oldest last
    });
  });

  group('allPastEventListWithSearchProvider tests', () {
    test(
      'should filter events by search term and keep the original order',
      () async {
        // Arrange - set search term
        container
            .read(eventListSearchTermProvider(testSpaceId).notifier)
            .state = '2';

        // Act
        final result = await container.read(
          allPastEventListWithSearchProvider(testSpaceId).future,
        );

        // Assert
        expect(result.length, equals(1));
        expect(result[0].title(), equals('Event 2'));
      },
    );

    test('empty search term should return all events in sorted order', () async {
      // Arrange - set empty search term
      container.read(eventListSearchTermProvider(testSpaceId).notifier).state =
          '';

      // Act
      final result = await container.read(
        allPastEventListWithSearchProvider(testSpaceId).future,
      );

      // Assert
      expect(result.length, equals(5));
      // Note: allPastEventListWithSearchProvider uses sortEventListAscTime which will sort in ASCENDING order
      // This is different from allPastEventListProvider which uses sortEventListDscTime
      expect(result[0].title(), equals('Event 1')); // newest first (descending)
      expect(result[1].title(), equals('Event 2'));
      expect(result[2].title(), equals('Event 3'));
      expect(result[3].title(), equals('Event 4'));
      expect(result[4].title(), equals('Event 5')); // oldest last (descending)
    });

    test(
      'search with multiple matches should return all matching events',
      () async {
        // Arrange - set search term that matches multiple events
        container
            .read(eventListSearchTermProvider(testSpaceId).notifier)
            .state = 'Event';

        // Act
        final result = await container.read(
          allPastEventListWithSearchProvider(testSpaceId).future,
        );

        // Assert
        expect(result.length, equals(5)); // all contain "Event"
        // Sorted in descending order
        expect(result[0].title(), equals('Event 1')); // newest first
        expect(result[4].title(), equals('Event 5')); // oldest last
      },
    );
  });
}
