import 'package:acter/features/events/model/event_location_model.dart';
import 'package:acter/features/events/providers/event_location_provider.dart';
import 'package:acter/features/events/widgets/add_event_location_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/mock_event_location.dart';
import '../../../helpers/test_util.dart';

void main() {
  late MockEventDraftLocationsNotifier mockLocationNotifier;

  setUp(() {
    mockLocationNotifier = MockEventDraftLocationsNotifier();
  });

  Future<void> pumpAddEventLocationWidget(
    WidgetTester tester, {
    EventLocationDraft? initialLocation,
  }) async {
    await tester.pumpProviderWidget(
      overrides: [
        eventDraftLocationsProvider.overrideWith((ref) => mockLocationNotifier),
      ],
      child: MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          body: AddEventLocationWidget(initialLocation: initialLocation),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('AddEventLocationWidget', () {
    testWidgets('displays virtual location form by default', (tester) async {
      await pumpAddEventLocationWidget(tester);

      final context = tester.element(find.byType(AddEventLocationWidget));
      final lang = L10n.of(context);

      // Verify default virtual location type is selected
      expect(find.text(lang.virtual), findsOneWidget);
      expect(find.text(lang.realWorld), findsOneWidget);

      // Verify form fields are present
      expect(find.text(lang.locationName), findsOneWidget);
      expect(find.text(lang.locationUrl), findsOneWidget);
      expect(find.text(lang.note), findsOneWidget);
    });

    testWidgets('displays physical location form when physical type is selected', (tester) async {
      await pumpAddEventLocationWidget(tester);

      // Tap physical location chip
      await tester.tap(find.text(L10n.of(tester.element(find.byType(AddEventLocationWidget))).realWorld));
      await tester.pumpAndSettle();

      // Verify physical location fields
      expect(find.text(L10n.of(tester.element(find.byType(AddEventLocationWidget))).addLocationAddress), findsOneWidget);
    });

    testWidgets('validates required fields for virtual location', (tester) async {
      await pumpAddEventLocationWidget(tester);

      // Try to submit without filling required fields
      await tester.tap(find.text(L10n.of(tester.element(find.byType(AddEventLocationWidget))).addLocation));
      await tester.pumpAndSettle();

      // Verify validation messages
      expect(find.text(L10n.of(tester.element(find.byType(AddEventLocationWidget))).pleaseEnterLocationName), findsOneWidget);
      expect(find.text(L10n.of(tester.element(find.byType(AddEventLocationWidget))).pleaseEnterLocationUrl), findsOneWidget);
    });

    testWidgets('validates required fields for physical location', (tester) async {
      await pumpAddEventLocationWidget(tester);

      // Switch to physical location
      await tester.tap(find.text(L10n.of(tester.element(find.byType(AddEventLocationWidget))).realWorld));
      await tester.pumpAndSettle();

      // Try to submit without filling required fields
      await tester.tap(find.text(L10n.of(tester.element(find.byType(AddEventLocationWidget))).addLocation));
      await tester.pumpAndSettle();

      // Verify validation messages
      expect(find.text(L10n.of(tester.element(find.byType(AddEventLocationWidget))).pleaseEnterLocationName), findsOneWidget);
      expect(find.text(L10n.of(tester.element(find.byType(AddEventLocationWidget))).pleaseEnterLocationAddress), findsOneWidget);
    });

    testWidgets('adds new virtual location successfully', (tester) async {
      await pumpAddEventLocationWidget(tester);

      // Fill in the form
      await tester.enterText(find.byType(TextFormField).first, 'Test Location');
      await tester.enterText(find.byType(TextFormField).last, 'https://test.com');

      // Submit the form
      await tester.tap(find.text(L10n.of(tester.element(find.byType(AddEventLocationWidget))).addLocation));
      await tester.pumpAndSettle();

      // Verify the location was added
      expect(mockLocationNotifier.state.length, 1);
      expect(mockLocationNotifier.state.first.name, 'Test Location');
      expect(mockLocationNotifier.state.first.url, 'https://test.com');
    });

    testWidgets('edits existing location successfully', (tester) async {
      final initialLocation = EventLocationDraft(
        name: 'Initial Location',
        type: LocationType.virtual,
        url: 'https://initial.com',
        note: 'Initial note',
      );

      // Add the initial location to the mock notifier's state
      mockLocationNotifier.addLocation(initialLocation);

      await pumpAddEventLocationWidget(tester, initialLocation: initialLocation);

      // Verify initial values are populated
      expect(find.text('Initial Location'), findsOneWidget);
      expect(find.text('https://initial.com'), findsOneWidget);

      // Update the form
      await tester.enterText(find.byType(TextFormField).first, 'Updated Location');
      await tester.enterText(find.byType(TextFormField).last, 'https://updated.com');

      // Submit the form
      await tester.tap(find.text(L10n.of(tester.element(find.byType(AddEventLocationWidget))).updateLocation));
      await tester.pumpAndSettle();

      // Verify the location was updated
      expect(mockLocationNotifier.state.length, 1);
      expect(mockLocationNotifier.state.first.name, 'Updated Location');
      expect(mockLocationNotifier.state.first.url, 'https://updated.com');
    });

    testWidgets('cancels form submission', (tester) async {
      await pumpAddEventLocationWidget(tester);

      // Tap cancel button
      await tester.tap(find.text(L10n.of(tester.element(find.byType(AddEventLocationWidget))).cancel));
      await tester.pumpAndSettle();

      // Verify no location was added
      expect(mockLocationNotifier.state.isEmpty, true);
    });
  });
} 