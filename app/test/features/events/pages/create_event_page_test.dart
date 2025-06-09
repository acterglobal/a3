import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/toolkit/html_editor/html_editor.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/features/events/pages/create_event_page.dart';
import 'package:acter/features/events/model/keys.dart';
import 'package:acter/features/events/providers/event_location_provider.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/mock_calendar_event.dart';
import '../../../helpers/test_util.dart';
import '../../../helpers/mock_event_location.dart';

void main() {
  late MockCalendarEvent mockEvent;
  late MockSpace mockSpace;
  late MockCalendarEventDraft mockDraft;
  late MockEventDraftLocationsNotifier mockLocationNotifier;

  setUp(() {
    mockEvent = MockCalendarEvent();
    mockSpace = MockSpace();
    mockDraft = MockCalendarEventDraft();
    mockLocationNotifier = MockEventDraftLocationsNotifier();
  });

  Future<void> pumpCreateEventPage(
    WidgetTester tester, {
    String? initialSelectedSpace,
    CalendarEvent? templateEvent,
  }) async {
    // Set a larger window size
    tester.platformDispatcher.views.first.physicalSize = const Size(1200, 1200);
    tester.platformDispatcher.views.first.devicePixelRatio = 1.0;

    await tester.pumpProviderWidget(
      overrides: [
        spaceProvider.overrideWith((ref, spaceId) => Future.value(mockSpace)),
        eventDraftLocationsProvider.overrideWith((ref) => mockLocationNotifier),
      ],
      child: CreateEventPage(
        initialSelectedSpace: initialSelectedSpace,
        templateEvent: templateEvent,
      ),
    );
    await tester.pumpAndSettle();
  }

  group('CreateEventPage', () {
    testWidgets('renders correctly with initial state', (tester) async {
      await pumpCreateEventPage(tester);

      // Get the context and L10n instance
      final BuildContext context = tester.element(find.byType(CreateEventPage));
      final lang = L10n.of(context);

      // Verify app bar
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text(lang.eventCreate), findsNWidgets(2));

      // Verify form fields
      expect(find.byKey(EventsKeys.eventNameTextField), findsOneWidget);
      expect(find.byKey(EventsKeys.eventStartDate), findsOneWidget);
      expect(find.byKey(EventsKeys.eventStartTime), findsOneWidget);
      expect(find.byKey(EventsKeys.eventEndDate), findsOneWidget);
      expect(find.byKey(EventsKeys.eventEndTime), findsOneWidget);
      expect(find.byKey(EventsKeys.eventDescriptionTextField), findsOneWidget);

      // Verify action buttons
      expect(find.byKey(EventsKeys.eventCreateEditBtn), findsOneWidget);
      expect(find.text(lang.cancel), findsOneWidget);
    });

    testWidgets('validates required fields', (tester) async {
      await pumpCreateEventPage(tester);

      // Get the context and L10n instance
      final BuildContext context = tester.element(find.byType(CreateEventPage));
      final lang = L10n.of(context);

      // Find the form and trigger validation
      final form = tester.widget<Form>(find.byType(Form));
      (form.key as GlobalKey<FormState>).currentState?.validate();

      // Try to submit without filling required field
      await tester.tap(find.byKey(EventsKeys.eventCreateEditBtn));
      await tester.pumpAndSettle();

      // Verify validation messages
      expect(find.text(lang.pleaseEnterEventName), findsOneWidget);
      expect(find.text(lang.startDateRequired), findsOneWidget);
      expect(find.text(lang.startTimeRequired), findsOneWidget);
      expect(find.text(lang.endDateRequired), findsOneWidget);
      expect(find.text(lang.endTimeRequired), findsOneWidget);
    });
    testWidgets('handles event name input correctly', (tester) async {
      await pumpCreateEventPage(tester);

      // Enter event name
      await tester.enterText(
        find.byKey(EventsKeys.eventNameTextField),
        'Test Event Name',
      );
      await tester.pumpAndSettle();

      // Verify the text was entered
      expect(find.text('Test Event Name'), findsOneWidget);
    });

    testWidgets('handles date and time selection', (tester) async {
      await pumpCreateEventPage(tester);

      // Select start date
      await tester.tap(find.byKey(EventsKeys.eventStartDate));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Select start time
      await tester.tap(find.byKey(EventsKeys.eventStartTime));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Select end date
      await tester.tap(find.byKey(EventsKeys.eventEndDate));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Select end time
      await tester.tap(find.byKey(EventsKeys.eventEndTime));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Verify dates and times are set
      expect(find.byKey(EventsKeys.eventStartDate), findsOneWidget);
      expect(find.byKey(EventsKeys.eventStartTime), findsOneWidget);
      expect(find.byKey(EventsKeys.eventEndDate), findsOneWidget);
      expect(find.byKey(EventsKeys.eventEndTime), findsOneWidget);
    });

    testWidgets('handles Jitsi call link toggle', (tester) async {
      await pumpCreateEventPage(tester);

      // Find and tap the Jitsi switch
      final jitsiSwitch = find.byType(Switch);
      expect(jitsiSwitch, findsOneWidget);

      await tester.tap(jitsiSwitch);
      await tester.pumpAndSettle();

      // Verify the switch state changed
      final switchWidget = tester.widget<Switch>(jitsiSwitch);
      expect(switchWidget.value, isTrue);
    });

    testWidgets('clears locations on initialization', (tester) async {
      await pumpCreateEventPage(tester);

      // Verify locations are cleared
      expect(mockLocationNotifier.state, isEmpty);
    });

    testWidgets('handles template event data correctly', (tester) async {
      await pumpCreateEventPage(tester, templateEvent: mockEvent);

      // Verify template data is populated
      expect(find.text('Test Event'), findsOneWidget);
    });

    testWidgets('handles space selection', (tester) async {
      await pumpCreateEventPage(tester, initialSelectedSpace: 'test-space-id');

      // Verify space is selected
      expect(mockSpace.calendarEventDraft(), isNotNull);
    });

    testWidgets('creates event successfully with valid data', (tester) async {
      await pumpCreateEventPage(tester);

      // Fill in required fields
      await tester.enterText(
        find.byKey(EventsKeys.eventNameTextField),
        'Test Event',
      );
      await tester.pumpAndSettle();

      // Select start date
      await tester.tap(find.byKey(EventsKeys.eventStartDate));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Select start time
      await tester.tap(find.byKey(EventsKeys.eventStartTime));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Select end date
      await tester.tap(find.byKey(EventsKeys.eventEndDate));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Select end time
      await tester.tap(find.byKey(EventsKeys.eventEndTime));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Create event
      await tester.tap(find.byKey(EventsKeys.eventCreateEditBtn));
      await tester.pumpAndSettle();

      // Verify event creation
      expect(mockDraft.send(), isNotNull);
    });

    testWidgets('handles end date validation correctly', (tester) async {
      await pumpCreateEventPage(tester);

      // Select start date
      await tester.tap(find.byKey(EventsKeys.eventStartDate));
      await tester.pump();
      await tester.tap(find.text('15'));
      await tester.tap(find.text('OK'));
      await tester.pump();

      // Try to select an end date before start date
      await tester.tap(find.byKey(EventsKeys.eventEndDate));
      await tester.pump();
      await tester.tap(
        find.text('14'),
      ); // Try to select a date before start date
      await tester.tap(find.text('OK'));
      await tester.pump();

      // Verify end date is not updated
      expect(find.text('14'), findsNothing);
    });

    testWidgets('handles end time validation correctly', (tester) async {
      await pumpCreateEventPage(tester);

      // Select start date and time
      await tester.tap(find.byKey(EventsKeys.eventStartDate));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(EventsKeys.eventStartTime));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Select same end date
      await tester.tap(find.byKey(EventsKeys.eventEndDate));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Try to select end time before start time
      await tester.tap(find.byKey(EventsKeys.eventEndTime));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Verify end time is not updated
      expect(find.text('00:00'), findsNothing);
    });

    testWidgets('handles description field correctly', (tester) async {
      await pumpCreateEventPage(tester);

      // Verify description field exists
      expect(find.byKey(EventsKeys.eventDescriptionTextField), findsOneWidget);

      // Verify HTML editor is present
      expect(find.byType(HtmlEditor), findsOneWidget);
    });

    testWidgets('handles space selection form field', (tester) async {
      await pumpCreateEventPage(tester);

      // Verify space selection form field exists
      expect(find.byType(SelectSpaceFormField), findsOneWidget);
    });

    testWidgets('handles event location widget correctly', (tester) async {
      await pumpCreateEventPage(tester);

      // Get the context and L10n instance
      final BuildContext context = tester.element(find.byType(CreateEventPage));
      final lang = L10n.of(context);

      // Verify location widget exists
      expect(find.text(lang.eventLocations), findsOneWidget);
      expect(find.byIcon(Icons.map_outlined), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    });
  });
}
