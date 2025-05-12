import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/eventDateChange.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/rsvpMaybe.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/rsvpNo.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/rsvpYes.dart';
import 'package:acter_notifify/model/push_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../common/mock_data/mock_avatar_info.dart';
import '../../../helpers/test_util.dart';
import '../mock_data/mock_activity.dart';
import '../mock_data/mock_activity_object.dart';
import '../mock_data/mock_date_time_range_change.dart';
import '../mock_data/mock_ref_details.dart';

void main() {
  testWidgets('Date time range changed on Event Object', (tester) async {
    MockActivity mockActivity = MockActivity(
      mockType: PushStyles.eventDateChange.name,
      mockDateTimeRangeContent: MockDateTimeRangeContent(),
      mockObject: MockActivityObject(
        mockType: 'event',
        mockEmoji: '🗓️',
        mockTitle: 'Team Meeting',
      ),
      mockRefDetails: MockRefDetails(
        mockTitle: 'Planning',
        mockType: 'calendar-event',
        mockTargetId: 'event-id',
      ),
    );

    await tester.pumpProviderWidget(
      overrides: [
        memberAvatarInfoProvider.overrideWith(
          (ref, param) =>
              MockAvatarInfo(uniqueId: param.userId, mockDisplayName: 'User-1'),
        ),
      ],
      child: Material(
        child: ActivityEventDateChangeItemWidget(activity: mockActivity),
      ),
    );
    // Wait for the async provider to load
    await tester.pumpAndSettle();

    // Verify action icon
    expect(find.byIcon(Icons.access_time), findsOneWidget);

    // Verify action title
    expect(find.text('Rescheduled'), findsOneWidget);

    // Verify object icon
    expect(find.byIcon(PhosphorIconsRegular.calendar), findsAtLeast(1));

    // Verify object info
    expect(find.text('Team Meeting'), findsOneWidget);

    // Verify user info
    expect(find.text('User-1'), findsOneWidget);

    // Verify the change text is displayed
    expect(find.textContaining('changed the start time'), findsOneWidget);
  });

  testWidgets('RSVP yes for Event Object', (tester) async {
    MockActivity mockActivity = MockActivity(
      mockType: PushStyles.rsvpYes.name,
      mockObject: MockActivityObject(
        mockType: 'event',
        mockEmoji: '🗓️',
        mockTitle: 'Team Meeting',
      ),
      mockRefDetails: MockRefDetails(
        mockTitle: 'Team meeting',
        mockType: 'calendar-event',
        mockTargetId: 'event-id',
      ),
    );

    await tester.pumpProviderWidget(
      overrides: [
        memberAvatarInfoProvider.overrideWith(
          (ref, param) =>
              MockAvatarInfo(uniqueId: param.userId, mockDisplayName: 'User-1'),
        ),
      ],
      child: Material(
        child: ActivityEventRSVPYesItemWidget(activity: mockActivity),
      ),
    );
    // Wait for the async provider to load
    await tester.pump();

    // Verify action icon
    expect(find.byIcon(Icons.check_circle_outlined), findsOneWidget);

    // Verify action title
    expect(find.text('Going to'), findsOneWidget);

    // Verify object icon
    expect(find.byIcon(PhosphorIconsRegular.calendar), findsAtLeast(1));

    // Verify object info
    expect(find.text('Team Meeting'), findsOneWidget);

    // Verify user info
    expect(find.text('User-1'), findsOneWidget);
  });

  testWidgets('RSVP May be for Event Object', (tester) async {
    MockActivity mockActivity = MockActivity(
      mockType: PushStyles.rsvpMaybe.name,
      mockObject: MockActivityObject(
        mockType: 'event',
        mockEmoji: '🗓️',
        mockTitle: 'Team Meeting',
      ),
      mockRefDetails: MockRefDetails(
        mockTitle: 'Team meeting',
        mockType: 'calendar-event',
        mockTargetId: 'event-id',
      ),
    );

    await tester.pumpProviderWidget(
      overrides: [
        memberAvatarInfoProvider.overrideWith(
          (ref, param) =>
              MockAvatarInfo(uniqueId: param.userId, mockDisplayName: 'User-1'),
        ),
      ],
      child: Material(
        child: ActivityEventRSVPMayBeItemWidget(activity: mockActivity),
      ),
    );
    // Wait for the async provider to load
    await tester.pump();

    // Verify action icon
    expect(find.byIcon(Icons.question_mark), findsOneWidget);

    // Verify action title
    expect(find.text('Might be attending'), findsOneWidget);

    // Verify object icon
    expect(find.byIcon(PhosphorIconsRegular.calendar), findsAtLeast(1));

    // Verify object info
    expect(find.text('Team Meeting'), findsOneWidget);

    // Verify user info
    expect(find.text('User-1'), findsOneWidget);
  });

  testWidgets('RSVP No for Event Object', (tester) async {
    MockActivity mockActivity = MockActivity(
      mockType: PushStyles.rsvpNo.name,
      mockObject: MockActivityObject(
        mockType: 'event',
        mockEmoji: '🗓️',
        mockTitle: 'Team Meeting',
      ),
      mockRefDetails: MockRefDetails(
        mockTitle: 'Team meeting',
        mockType: 'calendar-event',
        mockTargetId: 'event-id',
      ),
    );

    await tester.pumpProviderWidget(
      overrides: [
        memberAvatarInfoProvider.overrideWith(
          (ref, param) =>
              MockAvatarInfo(uniqueId: param.userId, mockDisplayName: 'User-1'),
        ),
      ],
      child: Material(
        child: ActivityEventRSVPNoItemWidget(activity: mockActivity),
      ),
    );
    // Wait for the async provider to load
    await tester.pump();

    // Verify action icon
    expect(find.byIcon(Icons.close), findsOneWidget);

    // Verify action title
    expect(find.text('Not Going to'), findsOneWidget);

    // Verify object icon
    expect(find.byIcon(PhosphorIconsRegular.calendar), findsAtLeast(1));

    // Verify object info
    expect(find.text('Team Meeting'), findsOneWidget);

    // Verify user info
    expect(find.text('User-1'), findsOneWidget);
  });
}
