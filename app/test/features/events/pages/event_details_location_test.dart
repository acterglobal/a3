import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/events/pages/event_details_page.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/providers/event_type_provider.dart';
import 'package:acter/features/events/providers/notifiers/event_notifiers.dart';
import 'package:acter/features/events/providers/event_location_provider.dart';
import 'package:acter/features/events/widgets/view_physical_location_widget.dart';
import 'package:acter/features/events/widgets/view_virtual_location_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../../helpers/mock_calendar_event.dart';
import '../../../helpers/mock_event_providers.dart';
import '../../../helpers/test_util.dart';
import '../../../helpers/mock_event_location.dart';

void main() {
  late AsyncCalendarEventNotifier mockEventNotifier;
  late MockAsyncParticipantsNotifier mockParticipantsNotifier;
  late MockAsyncRsvpStatusNotifier mockRsvpStatusNotifier;
  late MockAsyncEventLocationsNotifier mockLocationsNotifier;

  setUp(() {
    mockParticipantsNotifier = MockAsyncParticipantsNotifier(shouldFail: false);
    mockRsvpStatusNotifier = MockAsyncRsvpStatusNotifier();
    mockLocationsNotifier = MockAsyncEventLocationsNotifier();

    // Register fallback values for the mocks
    registerFallbackValue(MockCalendarEvent());
    registerFallbackValue(MockEventLocationInfo());
  });

  Future<void> pumpEventDetailsPage(
    WidgetTester tester,
    MockCalendarEvent mockEvent,
  ) async {
    // Set up event notifier using MockFindAsyncCalendarEventNotifier
    mockEventNotifier = MockFindAsyncCalendarEventNotifier(events: [mockEvent]);

    await tester.pumpProviderWidget(
      overrides: [
        calendarEventProvider.overrideWith(() => mockEventNotifier),
        participantsProvider.overrideWith(() => mockParticipantsNotifier),
        myRsvpStatusProvider.overrideWith(() => mockRsvpStatusNotifier),
        roomMembershipProvider.overrideWith((a, b) => null),
        roomDisplayNameProvider.overrideWith((a, b) => 'Test Space'),
        eventTypeProvider.overrideWith((ref, event) => EventFilters.upcoming),
        asyncEventLocationsProvider.overrideWith(() => mockLocationsNotifier),
      ],
      child: const EventDetailPage(calendarId: 'test-event-id'),
    );
    await tester.pump();
  }

  group('Event Details Location Tests', () {
    testWidgets('displays physical location correctly', (tester) async {
      // Set up mock physical location using constructor
      final mockLocation = MockEventLocationInfo(
        name: 'Office Building',
        locationType: 'physical',
        address: '123 Main St, City',
        notes: 'Main entrance',
      );

      // Set up mock event with location
      final mockEvent = MockCalendarEvent(
        title: 'Test Event',
        eventId: 'test-event-id',
        locations: [mockLocation],
      );

      // Set up locations notifier to return the mock location
      mockLocationsNotifier.setLocations([mockLocation]);

      await pumpEventDetailsPage(tester, mockEvent);

      // Verify physical location display
      expect(find.text('Office Building'), findsOneWidget);
      expect(find.text('123 Main St, City'), findsOneWidget);
      expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    });

    testWidgets('displays virtual location correctly', (tester) async {
      // Set up mock virtual location
      final mockLocation = MockEventLocationInfo(
        name: 'Zoom Meeting',
        locationType: 'virtual',
        uri: 'https://zoom.us/j/123456789',
        notes: 'Password: 1234',
      );

      // Set up mock event with location
      final mockEvent = MockCalendarEvent(
        title: 'Test Event',
        eventId: 'test-event-id',
        locations: [mockLocation],
      );

      // Set up locations notifier to return the mock location
      mockLocationsNotifier.setLocations([mockLocation]);

      await pumpEventDetailsPage(tester, mockEvent);

      // Verify virtual location display
      expect(find.text('Zoom Meeting'), findsOneWidget);
      expect(find.text('https://zoom.us/j/123456789'), findsOneWidget);
      expect(find.byIcon(Icons.language), findsOneWidget);
    });

    testWidgets('displays multiple locations correctly', (tester) async {
      // Set up mock physical location
      final mockPhysicalLocation = MockEventLocationInfo(
        name: 'Office Building',
        locationType: 'physical',
        address: '123 Main St, City',
        notes: 'Main entrance',
      );

      // Set up mock virtual location
      final mockVirtualLocation = MockEventLocationInfo(
        name: 'Zoom Meeting',
        locationType: 'virtual',
        uri: 'https://zoom.us/j/123456789',
        notes: 'Password: 1234',
      );

      // Set up mock event with locations
      final mockEvent = MockCalendarEvent(
        title: 'Test Event',
        eventId: 'test-event-id',
        locations: [mockPhysicalLocation, mockVirtualLocation],
      );

      // Set up locations notifier to return the mock locations
      mockLocationsNotifier.setLocations([
        mockPhysicalLocation,
        mockVirtualLocation,
      ]);

      await pumpEventDetailsPage(tester, mockEvent);

      // Verify both locations are displayed
      expect(find.text('Office Building'), findsOneWidget);
      expect(find.text('123 Main St, City'), findsOneWidget);
      expect(find.text('Zoom Meeting'), findsOneWidget);
      expect(find.text('https://zoom.us/j/123456789'), findsOneWidget);
      expect(find.byIcon(Icons.map_outlined), findsOneWidget);
      expect(find.byIcon(Icons.language), findsOneWidget);
    });

    testWidgets('displays no locations when none are provided', (tester) async {
      // Set up mock event without locations
      final mockEvent = MockCalendarEvent(
        title: 'Test Event',
        eventId: 'test-event-id',
        locations: [],
      );

      // Set up locations notifier to return empty list
      mockLocationsNotifier.setLocations([]);

      await pumpEventDetailsPage(tester, mockEvent);

      // Verify no locations are displayed
      expect(find.byIcon(Icons.map_outlined), findsNothing);
      expect(find.byIcon(Icons.language), findsNothing);
    });

    testWidgets(
      'shows location notes in modal when physical location is tapped',
      (tester) async {
        // Set up mock location with notes
        final mockLocation = MockEventLocationInfo(
          name: 'Office Building',
          locationType: 'physical',
          address: '123 Main St, City',
          notes: 'Please use the main entrance and check in at reception',
        );

        // Set up mock event with location
        final mockEvent = MockCalendarEvent(
          title: 'Test Event',
          eventId: 'test-event-id',
          locations: [mockLocation],
        );

        // Set up locations notifier to return the mock location
        mockLocationsNotifier.setLocations([mockLocation]);

        await pumpEventDetailsPage(tester, mockEvent);

        // Find the ListTile containing the location name
        final locationTile = find.byWidgetPredicate(
          (widget) =>
              widget is ListTile &&
              widget.title is Text &&
              (widget.title as Text).data == 'Office Building',
        );
        expect(locationTile, findsOneWidget);

        // Ensure the widget is visible
        await tester.ensureVisible(locationTile);
        await tester.pump();

        // Tap the ListTile and wait for modal
        await tester.tap(locationTile);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify modal content
        expect(find.byType(ViewPhysicalLocationWidget), findsOneWidget);
        expect(
          find.text('Please use the main entrance and check in at reception'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows location notes in modal when virtual location is tapped',
      (tester) async {
        // Set up mock location with notes
        final mockLocation = MockEventLocationInfo(
          name: 'Zoom Meeting',
          locationType: 'virtual',
          uri: 'https://zoom.us/j/123456789',
          notes: 'Password: 1234',
        );

        // Set up mock event with location
        final mockEvent = MockCalendarEvent(
          title: 'Test Event',
          eventId: 'test-event-id',
          locations: [mockLocation],
        );

        // Set up locations notifier to return the mock location
        mockLocationsNotifier.setLocations([mockLocation]);

        await pumpEventDetailsPage(tester, mockEvent);

        // Find the ListTile containing the location name
        final locationTile = find.byWidgetPredicate(
          (widget) =>
              widget is ListTile &&
              widget.title is Text &&
              (widget.title as Text).data == 'Zoom Meeting',
        );
        expect(locationTile, findsOneWidget);

        // Ensure the widget is visible
        await tester.ensureVisible(locationTile);
        await tester.pump();

        // Tap the ListTile and wait for modal
        await tester.tap(locationTile);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify modal content
        expect(find.byType(ViewVirtualLocationWidget), findsOneWidget);
        expect(find.text('Password: 1234'), findsOneWidget);
      },
    );
  });
}
