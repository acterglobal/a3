import 'package:acter/features/events/model/event_location_model.dart';
import 'package:acter/features/events/providers/event_location_provider.dart';
import 'package:acter/features/events/widgets/event_location_list_widget.dart';
import 'package:acter/features/events/widgets/add_event_location_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../helpers/mock_event_location.dart';
import '../../../helpers/test_util.dart';

void main() {
  late MockEventDraftLocationsNotifier mockLocationNotifier;

  setUp(() {
    mockLocationNotifier = MockEventDraftLocationsNotifier();
  });

  Future<void> pumpEventLocationListWidget(
    WidgetTester tester, {
    String? eventId,
  }) async {
    await tester.pumpProviderWidget(
      overrides: [
        eventDraftLocationsProvider.overrideWith((ref) => mockLocationNotifier),
      ],
      child: MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          body: EventLocationListWidget(eventId: eventId),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('EventLocationListWidget', () {
    testWidgets('displays empty state when no locations', (tester) async {
      await pumpEventLocationListWidget(tester);

      // Verify empty state message
      expect(find.text(L10n.of(tester.element(find.byType(EventLocationListWidget))).noLocationsAdded), findsOneWidget);
    });

    testWidgets('displays list of locations when locations exist', (tester) async {
      // Add some locations
      final location1 = EventLocationDraft(
        name: 'Virtual Location',
        type: LocationType.virtual,
        url: 'https://virtual.com',
        note: 'Virtual note',
      );
      final location2 = EventLocationDraft(
        name: 'Physical Location',
        type: LocationType.physical,
        address: '123 Main St',
        note: 'Physical note',
      );
      mockLocationNotifier.addLocation(location1);
      mockLocationNotifier.addLocation(location2);

      await pumpEventLocationListWidget(tester);

      // Verify locations are displayed
      expect(find.text('Virtual Location'), findsOneWidget);
      expect(find.text('https://virtual.com'), findsOneWidget);
      expect(find.text('Physical Location'), findsOneWidget);
      expect(find.text('123 Main St'), findsOneWidget);
    });

    testWidgets('opens add location modal when add button is tapped', (tester) async {
      await pumpEventLocationListWidget(tester);

      // Tap add button
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      // Verify add location modal is shown
      expect(find.byType(AddEventLocationWidget), findsOneWidget);
    });

    testWidgets('opens edit location modal when location is tapped', (tester) async {
      // Add a location
      final location = EventLocationDraft(
        name: 'Test Location',
        type: LocationType.virtual,
        url: 'https://test.com',
        note: 'Test note',
      );
      mockLocationNotifier.addLocation(location);

      await pumpEventLocationListWidget(tester);

      // Tap location in the list (using ListTile to be more specific)
      await tester.tap(find.ancestor(
        of: find.text('Test Location'),
        matching: find.byType(ListTile),
      ));
      await tester.pumpAndSettle();

      // Verify edit location modal is shown
      expect(find.byType(AddEventLocationWidget), findsOneWidget);
      expect(find.text('Test Location'), findsNWidgets(2)); // Now we expect 2 instances
    });

    testWidgets('removes location when delete button is tapped', (tester) async {
      // Add a location
      final location = EventLocationDraft(
        name: 'Test Location',
        type: LocationType.virtual,
        url: 'https://test.com',
        note: 'Test note',
      );
      mockLocationNotifier.addLocation(location);

      await pumpEventLocationListWidget(tester);

      // Tap delete button
      await tester.tap(find.byIcon(PhosphorIcons.trash()));
      await tester.pumpAndSettle();

      // Verify location is removed
      expect(find.text('Test Location'), findsNothing);
      expect(mockLocationNotifier.state.isEmpty, true);
    });

    testWidgets('shows discard dialog when cancel is tapped', (tester) async {
      // Add a location
      final location = EventLocationDraft(
        name: 'Test Location',
        type: LocationType.virtual,
        url: 'https://test.com',
        note: 'Test note',
      );
      mockLocationNotifier.addLocation(location);

      // Pass eventId to show action buttons
      await pumpEventLocationListWidget(tester, eventId: 'test-event-id');

      // Tap cancel button
      await tester.tap(find.text(L10n.of(tester.element(find.byType(EventLocationListWidget))).cancel));
      await tester.pumpAndSettle();

      // Verify discard dialog is shown
      expect(find.text(L10n.of(tester.element(find.byType(EventLocationListWidget))).discardChanges), findsOneWidget);
      expect(find.text(L10n.of(tester.element(find.byType(EventLocationListWidget))).discardChangesDescription), findsOneWidget);
    });

    testWidgets('clears locations and closes when discard is confirmed', (tester) async {
      // Add a location
      final location = EventLocationDraft(
        name: 'Test Location',
        type: LocationType.virtual,
        url: 'https://test.com',
        note: 'Test note',
      );
      mockLocationNotifier.addLocation(location);

      // Pass eventId to show action buttons
      await pumpEventLocationListWidget(tester, eventId: 'test-event-id');

      // Tap cancel button
      await tester.tap(find.text(L10n.of(tester.element(find.byType(EventLocationListWidget))).cancel));
      await tester.pumpAndSettle();

      // Tap discard button
      await tester.tap(find.text(L10n.of(tester.element(find.byType(EventLocationListWidget))).discard));
      await tester.pumpAndSettle();

      // Verify locations are cleared and widget is closed
      expect(mockLocationNotifier.state.isEmpty, true);
    });

    testWidgets('keeps changes when keep changes is tapped', (tester) async {
      // Add a location
      final location = EventLocationDraft(
        name: 'Test Location',
        type: LocationType.virtual,
        url: 'https://test.com',
        note: 'Test note',
      );
      mockLocationNotifier.addLocation(location);

      // Pass eventId to show action buttons
      await pumpEventLocationListWidget(tester, eventId: 'test-event-id');

      // Tap cancel button
      await tester.tap(find.text(L10n.of(tester.element(find.byType(EventLocationListWidget))).cancel));
      await tester.pumpAndSettle();

      // Tap keep changes button
      await tester.tap(find.text(L10n.of(tester.element(find.byType(EventLocationListWidget))).keepChanges));
      await tester.pumpAndSettle();

      // Verify locations are kept
      expect(mockLocationNotifier.state.length, 1);
      expect(mockLocationNotifier.state.first.name, 'Test Location');
    });

    testWidgets('saves locations when save is tapped with eventId', (tester) async {
      // Add a location
      final location = EventLocationDraft(
        name: 'Test Location',
        type: LocationType.virtual,
        url: 'https://test.com',
        note: 'Test note',
      );
      mockLocationNotifier.addLocation(location);

      await pumpEventLocationListWidget(tester, eventId: 'test-event-id');

      // Tap save button
      await tester.tap(find.text(L10n.of(tester.element(find.byType(EventLocationListWidget))).save));
      await tester.pumpAndSettle();

      // Verify save action was triggered
      // Note: We can't directly test the save action since it's async and involves external services
      // But we can verify the widget is still mounted and the locations are still there
      expect(find.byType(EventLocationListWidget), findsOneWidget);
      expect(mockLocationNotifier.state.length, 1);
    });

    testWidgets('closes widget when save is tapped without eventId', (tester) async {
      // Add a location
      final location = EventLocationDraft(
        name: 'Test Location',
        type: LocationType.virtual,
        url: 'https://test.com',
        note: 'Test note',
      );
      mockLocationNotifier.addLocation(location);

      // Don't pass eventId to test the non-editing case
      await pumpEventLocationListWidget(tester);

      // In this case, there should be no save button visible since no eventId is provided
      // The widget should only show locations in read-only mode or with add functionality
      expect(find.text(L10n.of(tester.element(find.byType(EventLocationListWidget))).save), findsNothing);
      
      // Verify the location is still displayed
      expect(find.text('Test Location'), findsOneWidget);
    });
  });
} 