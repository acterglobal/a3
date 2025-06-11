import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/errors/error_page.dart';
import 'package:acter/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:acter/features/events/model/keys.dart';
import 'package:acter/features/events/pages/event_details_page.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/providers/event_type_provider.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/features/attachments/widgets/attachment_section.dart';
import 'package:acter/features/comments/widgets/comments_section_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:atlas_icons/atlas_icons.dart';
import '../../../helpers/mock_a3sdk.dart' as a3sdk;
import '../../../helpers/mock_calendar_event.dart';
import '../../../helpers/mock_event_providers.dart';
import '../../../helpers/test_util.dart';
import '../../update/post_to_page_test.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter/common/widgets/edit_html_description_sheet.dart';
import 'package:acter/common/widgets/edit_title_sheet.dart';

void main() {
  late MockAsyncCalendarEventNotifier mockEventNotifier;
  late MockAsyncParticipantsNotifier mockParticipantsNotifier;
  late MockAsyncRsvpStatusNotifier mockRsvpStatusNotifier;

  setUp(() {
    mockEventNotifier = MockAsyncCalendarEventNotifier(shouldFail: false);
    mockParticipantsNotifier = MockAsyncParticipantsNotifier(
      shouldFail: false,
      participants: [],
    );
    mockRsvpStatusNotifier = MockAsyncRsvpStatusNotifier();

    // Register fallback values
    registerFallbackValue(MockCalendarEvent());
    registerFallbackValue(
      a3sdk.MockTextMessageContent(textBody: '', htmlBody: ''),
    );
  });

  Future<void> pumpEventDetailsPage(
    WidgetTester tester, {
    MockCalendarEvent? mockEvent,
  }) async {
    final event =
        mockEvent ??
        MockCalendarEvent(
          title: 'Test Event',
          eventId: 'test-event-id',
          roomId: 'test-room-id',
        );

    mockEventNotifier = MockAsyncCalendarEventNotifier(shouldFail: false);

    mockEventNotifier.setEvent(event);

    await tester.pumpProviderWidget(
      overrides: [
        calendarEventProvider.overrideWith(() => mockEventNotifier),
        participantsProvider.overrideWith(() => mockParticipantsNotifier),
        myRsvpStatusProvider.overrideWith(() => mockRsvpStatusNotifier),
        roomMembershipProvider.overrideWith((a, b) => null),
        isBookmarkedProvider.overrideWith((a, b) => false),
        roomDisplayNameProvider.overrideWith((a, b) => 'Test Space'),
        eventTypeProvider.overrideWith((ref, event) => EventFilters.upcoming),
      ],
      child: const EventDetailPage(calendarId: 'test-event-id'),
    );
    await tester.pump();
  }

  group('EventDetailPage', () {
    testWidgets('renders correctly with initial state', (tester) async {
      await pumpEventDetailsPage(tester);

      // Verify app bar
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byIcon(Atlas.calendar_dots).first, findsOneWidget);

      // Verify event details
      expect(find.text('Test Event'), findsOneWidget);
      expect(find.byType(SpaceChip), findsOneWidget);
    });

    testWidgets('displays event description', (tester) async {
      final mockDescription = a3sdk.MockTextMessageContent(
        textBody: 'Test Description',
        htmlBody: '<p>Test Description</p>',
      );

      final mockEvent = MockCalendarEvent(
        title: 'Test Event',
        eventId: 'test-event-id',
        roomId: 'test-room-id',
        description: mockDescription,
      );
      mockEventNotifier.setEvent(mockEvent);

      await pumpEventDetailsPage(tester, mockEvent: mockEvent);

      // Verify description is displayed
      expect(find.text('Test Description'), findsOneWidget);
    });

    testWidgets('displays error page when event loading fails', (tester) async {
      mockEventNotifier = MockAsyncCalendarEventNotifier(shouldFail: true);
      await pumpEventDetailsPage(tester);
      await tester.pump();

      // Verify error page
      expect(find.byType(ErrorPage), findsOneWidget);
    });

    testWidgets('displays participants list', (tester) async {
      mockParticipantsNotifier = MockAsyncParticipantsNotifier(
        shouldFail: false,
        participants: ['user1', 'user2'],
      );

      await pumpEventDetailsPage(tester);
      await tester.pump();

      // Get the context and L10n instance
      final BuildContext context = tester.element(find.byType(EventDetailPage));
      final lang = L10n.of(context);

      // Verify participants section
      expect(find.byIcon(Atlas.accounts_group_people).first, findsOneWidget);
      expect(find.text(lang.peopleGoing(2)), findsOneWidget);
    });

    testWidgets('handles event description editing', (tester) async {
      final mockDescription = a3sdk.MockTextMessageContent(
        textBody: 'Test Description',
        htmlBody: '<p>Test Description</p>',
      );

      final mockEvent = MockCalendarEvent(
        title: 'Test Event',
        eventId: 'test-event-id',
        roomId: 'test-room-id',
        description: mockDescription,
      );

      // Set up mock with edit permissions
      final mockMember = MockMember();
      when(() => mockMember.canString('CanPostEvent')).thenReturn(true);

      mockEventNotifier.setEvent(mockEvent);

      await tester.pumpProviderWidget(
        overrides: [
          calendarEventProvider.overrideWith(() => mockEventNotifier),
          participantsProvider.overrideWith(() => mockParticipantsNotifier),
          myRsvpStatusProvider.overrideWith(() => mockRsvpStatusNotifier),
          roomMembershipProvider.overrideWith((a, b) => mockMember),
          isBookmarkedProvider.overrideWith((a, b) => false),
          roomDisplayNameProvider.overrideWith((a, b) => 'Test Space'),
          eventTypeProvider.overrideWith((ref, event) => EventFilters.upcoming),
        ],
        child: const EventDetailPage(calendarId: 'test-event-id'),
      );
      await tester.pump();

      // Find and ensure the description text is visible
      final descriptionFinder = find.text('Test Description');
      expect(descriptionFinder, findsOneWidget);
      await tester.ensureVisible(descriptionFinder);
      await tester.pump();

      // Tap the description text
      await tester.tap(descriptionFinder, warnIfMissed: false);
      await tester.pump();

      // Wait for the modal to appear
      await tester.pump(const Duration(milliseconds: 500));

      // Verify edit description sheet is shown
      expect(find.byType(EditHtmlDescriptionSheet), findsOneWidget);
    });

    testWidgets('handles event title editing', (tester) async {
      final mockEvent = MockCalendarEvent(
        title: 'Test Event',
        eventId: 'test-event-id',
        roomId: 'test-room-id',
      );

      // Set up mock with edit permissions
      final mockMember = MockMember();
      when(() => mockMember.canString('CanPostEvent')).thenReturn(true);

      mockEventNotifier.setEvent(mockEvent);

      await tester.pumpProviderWidget(
        overrides: [
          calendarEventProvider.overrideWith(() => mockEventNotifier),
          participantsProvider.overrideWith(() => mockParticipantsNotifier),
          myRsvpStatusProvider.overrideWith(() => mockRsvpStatusNotifier),
          roomMembershipProvider.overrideWith((a, b) => mockMember),
          isBookmarkedProvider.overrideWith((a, b) => false),
          roomDisplayNameProvider.overrideWith((a, b) => 'Test Space'),
          eventTypeProvider.overrideWith((ref, event) => EventFilters.upcoming),
        ],
        child: const EventDetailPage(calendarId: 'test-event-id'),
      );
      await tester.pump();

      // Tap on title to edit
      await tester.tap(find.text('Test Event'), warnIfMissed: false);
      await tester.pump();

      // Verify edit title sheet is shown
      expect(find.byType(EditTitleSheet), findsOneWidget);
    });

    testWidgets('handles event deletion', (tester) async {
      final mockEvent = MockCalendarEvent(
        title: 'Test Event',
        eventId: 'test-event-id',
        roomId: 'test-room-id',
      );

      // Set up mock with deletion permission
      final mockMember = MockMember();
      when(() => mockMember.canString('CanPostEvent')).thenReturn(true);

      mockEventNotifier.setEvent(mockEvent);

      await tester.pumpProviderWidget(
        overrides: [
          calendarEventProvider.overrideWith(() => mockEventNotifier),
          participantsProvider.overrideWith(() => mockParticipantsNotifier),
          myRsvpStatusProvider.overrideWith(() => mockRsvpStatusNotifier),
          roomMembershipProvider.overrideWith((a, b) => mockMember),
          isBookmarkedProvider.overrideWith((a, b) => false),
          roomDisplayNameProvider.overrideWith((a, b) => 'Test Space'),
          eventTypeProvider.overrideWith((ref, event) => EventFilters.upcoming),
          canRedactProvider.overrideWith((ref, event) => true),
        ],
        child: const EventDetailPage(calendarId: 'test-event-id'),
      );
      await tester.pump();

      // Open action menu
      await tester.tap(find.byKey(EventsKeys.appbarMenuActionBtn));
      await tester.pump();

      // Get the context and L10n instance
      final BuildContext context = tester.element(find.byType(EventDetailPage));
      final lang = L10n.of(context);

      // Verify delete option is available
      expect(find.text(lang.eventRemove), findsOneWidget);
    });

    testWidgets('handles event reporting', (tester) async {
      await pumpEventDetailsPage(tester);

      // Open action menu
      await tester.tap(find.byKey(EventsKeys.appbarMenuActionBtn));
      await tester.pump();

      // Get the context and L10n instance
      final BuildContext context = tester.element(find.byType(EventDetailPage));
      final lang = L10n.of(context);

      // Verify report option
      expect(find.text(lang.eventReport), findsOneWidget);
    });

    testWidgets('displays attachments section', (tester) async {
      await pumpEventDetailsPage(tester);

      // Verify attachments section
      expect(find.byType(AttachmentSectionWidget), findsOneWidget);
    });

    testWidgets('displays comments section', (tester) async {
      await pumpEventDetailsPage(tester);

      // Verify comments section
      expect(find.byType(CommentsSectionWidget), findsOneWidget);
    });

    testWidgets('handles RSVP status changes for past events', (tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          calendarEventProvider.overrideWith(() => mockEventNotifier),
          participantsProvider.overrideWith(() => mockParticipantsNotifier),
          myRsvpStatusProvider.overrideWith(() => mockRsvpStatusNotifier),
          roomMembershipProvider.overrideWith((a, b) => null),
          isBookmarkedProvider.overrideWith((a, b) => false),
          roomDisplayNameProvider.overrideWith((a, b) => 'Test Space'),
          eventTypeProvider.overrideWith((ref, event) => EventFilters.past),
        ],
        child: const EventDetailPage(calendarId: 'test-event-id'),
      );
      await tester.pump();

      // Verify RSVP buttons are disabled
      expect(
        tester.widget<InkWell>(find.byKey(EventsKeys.eventRsvpGoingBtn)).onTap,
        isNull,
      );
    });

    testWidgets('handles event with no participants', (tester) async {
      mockParticipantsNotifier = MockAsyncParticipantsNotifier(
        shouldFail: false,
        participants: [],
      );

      await pumpEventDetailsPage(tester);

      // Get the context and L10n instance
      final BuildContext context = tester.element(find.byType(EventDetailPage));
      final lang = L10n.of(context);

      // Verify no participants message
      expect(find.text(lang.noParticipantsGoing), findsOneWidget);
    });

    testWidgets('handles event with no edit permissions', (tester) async {
      await pumpEventDetailsPage(tester);

      // Verify edit options are not available
      expect(find.byKey(EventsKeys.eventEditBtn), findsNothing);
    });
  });
}
