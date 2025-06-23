import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_membership_container_widget.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/attachment.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/comment.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/creation.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/descriptionChange.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/eventDateChange.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/otherChanges.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/reaction.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/references.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/roomAvatar.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/roomName.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/roomTopic.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/rsvpMaybe.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/rsvpNo.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/rsvpYes.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/taskAccepted.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/taskAdd.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/taskComplete.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/taskDecline.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/taskDueDateChange.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/taskReOpen.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/titleChange.dart';
import 'package:acter_notifify/model/push_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Activity;
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:acter/common/themes/acter_theme.dart';

import '../../../common/mock_data/mock_avatar_info.dart';
import '../../../helpers/test_util.dart';
import '../../../helpers/font_loader.dart';
import '../../comments/mock_data/mock_message_content.dart';
import '../mock_data/mock_activity.dart';
import '../mock_data/mock_activity_object.dart';
import '../mock_data/mock_membership_change.dart';
import '../mock_data/mock_ref_details.dart';
import '../mock_data/mock_room_topic_change.dart';
import '../mock_data/mock_title_change.dart';
import '../mock_data/mock_description_change.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadTestFonts();
  });

  group('Activity Type Widgets Tests', () {
    Future<void> createWidgetUnderTest({
      required WidgetTester tester,
      required Widget widget,
      String? screenshotPath,
    }) async {
      await tester.pumpProviderWidget(
        overrides: [
          memberAvatarInfoProvider.overrideWith(
            (ref, param) =>
                MockAvatarInfo(uniqueId: param.userId, mockDisplayName: 'Test User'),
          ),
        ],
        screenshotPath: screenshotPath,
        child: MaterialApp(
          theme: ActerTheme.theme,
          locale: const Locale('en', 'US'),
          localizationsDelegates: const [
            L10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: L10n.supportedLocales,
          home: Material(
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(16),
              child: widget,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    group('Showcase Golden Tests for All Type Widgets', () {
      final showcaseTypeWidgets = [
        {
          'name': 'comment',
          'widget': (Activity activity) => ActivityCommentItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.comment.name,
            mockMsgContent: MockMsgContent(bodyText: 'Showcase comment!'),
            mockObject: MockActivityObject(mockType: 'task', mockTitle: 'Task Title'),
          ),
          'expectedText': 'commented on',
          'expectedIcon': PhosphorIconsRegular.chatCenteredDots,
        },
        {
          'name': 'attachment',
          'widget': (Activity activity) => ActivityAttachmentItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.attachment.name,
            mockObject: MockActivityObject(mockType: 'task', mockTitle: 'Task Title'),
          ),
          'expectedText': 'added attachment on',
          'expectedIcon': PhosphorIconsRegular.paperclip,
        },
        {
          'name': 'creation',
          'widget': (Activity activity) => ActivityCreationItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.creation.name,
            mockObject: MockActivityObject(mockType: 'task', mockTitle: 'Task Title'),
          ),
          'expectedText': 'creation task',
          'expectedIcon': Icons.add_circle_outline,
        },
        {
          'name': 'title_change',
          'widget': (Activity activity) => ActivityTitleChangeItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.titleChange.name,
            mockObject: MockActivityObject(mockType: 'pin', mockTitle: 'pin Title'),
            mockTitleContent: MockTitleContent(
              mockChange: 'Changed',
              mockNewVal: 'New Pin Title',
            ),
          ),
          'expectedText': 'changed title task',
          'expectedIcon': PhosphorIconsThin.pencilSimpleLine,
        },
        {
          'name': 'description_change',
          'widget': (Activity activity) => ActivityDescriptionChangeItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.descriptionChange.name,
            mockObject: MockActivityObject(mockType: 'pin', mockTitle: 'pin Description'),
            mockDescriptionContent: MockDescriptionContent(
              mockChange: 'Changed',
              mockNewVal: 'New Pin Description',
            ),
          ),
          'expectedText': 'changed description task',
          'expectedIcon': PhosphorIconsThin.pencilSimpleLine,
        },
        {
          'name': 'event_date_change',
          'widget': (Activity activity) => ActivityEventDateChangeItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.eventDateChange.name,
            mockObject: MockActivityObject(mockType: 'event', mockTitle: 'Event Title'),
          ),
          'expectedText': 'rescheduled event',
          'expectedIcon': Icons.access_time,
        },
        {
          'name': 'room_name',
          'widget': (Activity activity) => ActivityRoomNameItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.roomName.name,
            mockObject: MockActivityObject(mockType: 'space', mockTitle: 'Space Name'),
          ),
          'expectedText': 'updated space name',
          'expectedIcon': null, // Uses default icon in container
        },
        {
          'name': 'room_topic',
          'widget': (Activity activity) => ActivityRoomTopicItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.roomTopic.name,
            mockObject: MockActivityObject(mockType: 'space', mockTitle: 'Space Topic'),
            mockRoomTopicContent: MockRoomTopicContent(
              mockChange: 'Set',
              mockNewVal: 'New Space Topic',
            ),
          ),
          'expectedText': 'set space description',
          'expectedIcon': PhosphorIconsThin.pencilSimpleLine,
        },
        {
          'name': 'room_avatar',
          'widget': (Activity activity) => ActivityRoomAvatarItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.roomAvatar.name,
            mockObject: MockActivityObject(mockType: 'space', mockTitle: 'Space Avatar'),
          ),
          'expectedText': 'updated space avatar',
          'expectedIcon': null, // Uses default icon in container
        },
        {
          'name': 'rsvp_yes',
          'widget': (Activity activity) => ActivityEventRSVPYesItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.rsvpYes.name,
            mockObject: MockActivityObject(mockType: 'event', mockTitle: 'Event Title'),
          ),
          'expectedText': 'going to',
          'expectedIcon': Icons.check,
        },
        {
          'name': 'rsvp_no',
          'widget': (Activity activity) => ActivityEventRSVPNoItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.rsvpNo.name,
            mockObject: MockActivityObject(mockType: 'event', mockTitle: 'Event Title'),
          ),
          'expectedText': 'not going to',
          'expectedIcon': Icons.close_rounded,
        },
        {
          'name': 'rsvp_maybe',
          'widget': (Activity activity) => ActivityEventRSVPMayBeItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.rsvpMaybe.name,
            mockObject: MockActivityObject(mockType: 'event', mockTitle: 'Event Title'),
          ),
          'expectedText': 'may be',
          'expectedIcon': Icons.question_mark,
        },
        {
          'name': 'task_add',
          'widget': (Activity activity) => ActivityTaskAddItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.taskAdd.name,
            mockObject: MockActivityObject(mockType: 'task', mockTitle: 'Task Title'),
            mockName: 'abc task',
          ),
          'expectedText': 'added task on',
          'expectedIcon': Icons.add_circle_outline,
          'expectedSubtitle': 'abc task',
        },
          {
            'name': 'task_complete',
          'widget': (Activity activity) => ActivityTaskCompleteItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.taskComplete.name,
            mockObject: MockActivityObject(mockType: 'task', mockTitle: 'Task Title'),
          ),
          'expectedText': 'completed task',
          'expectedIcon': Icons.done_all,
        },
        {
          'name': 'task_accepted',
          'widget': (Activity activity) => ActivityTaskAcceptedItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.taskAccept.name,
            mockObject: MockActivityObject(mockType: 'task', mockTitle: 'Task Title'),
          ),
          'expectedText': 'accepted task',
          'expectedIcon': Icons.done,
        },
        {
          'name': 'task_decline',
          'widget': (Activity activity) => ActivityTaskDeclineItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.taskDecline.name,
            mockObject: MockActivityObject(mockType: 'task', mockTitle: 'Task Title'),
          ),
          'expectedText': 'declined task',
          'expectedIcon': Icons.close_rounded,
        },
        {
          'name': 'task_reopen',
          'widget': (Activity activity) => ActivityTaskReOpenItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.taskReOpen.name,
            mockObject: MockActivityObject(mockType: 'task', mockTitle: 'Task Title'),
          ),
          'expectedText': 'reopened task',
          'expectedIcon': Icons.restart_alt,
        },
        {
          'name': 'task_due_date_change',
          'widget': (Activity activity) => ActivityTaskDueDateChangedItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.taskDueDateChange.name,
            mockObject: MockActivityObject(mockType: 'task', mockTitle: 'Task Title'),
          ),
          'expectedText': 'rescheduled task',
          'expectedIcon': Icons.access_time,
        },
        {
          'name': 'reaction',
          'widget': (Activity activity) => ActivityReactionItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.reaction.name,
            mockObject: MockActivityObject(mockType: 'news', mockTitle: 'News Title'),
          ),
          'expectedText': 'reacted on',
          'expectedIcon': Icons.favorite,
        },
        {
          'name': 'references',
          'widget': (Activity activity) => ActivityReferencesItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.references.name,
            mockObject: MockActivityObject(mockType: 'task', mockTitle: 'Task Title'),
            mockRefDetails: MockRefDetails(
              mockTitle: 'Task Title',
              mockType: 'task',
            ),
          ),
          'expectedText': 'added references on',
          'expectedIcon': PhosphorIconsRegular.link,
        },
        {
          'name': 'other_changes',
          'widget': (Activity activity) => ActivityOtherChangesItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.otherChanges.name,
            mockObject: MockActivityObject(mockType: 'task', mockTitle: 'Task Title'),
          ),
          'expectedText': 'updated task',
          'expectedIcon': PhosphorIconsRegular.pencilLine,
        },
        // Membership activities
        {
          'name': 'membership_joined',
          'widget': (Activity activity) => ActivityMembershipItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.joined.name,
            mockSenderId: '@user1:acter.global',
            mockMembershipContent: MockMembershipContent(
              mockChange: 'joined',
              mockUserId: '@user1:acter.global',
            ),
          ),
          'expectedText': 'joined',
          'expectedIcon': PhosphorIconsThin.users,
        },
        {
          'name': 'membership_left',
          'widget': (Activity activity) => ActivityMembershipItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.left.name,
            mockSenderId: '@user1:acter.global',
            mockMembershipContent: MockMembershipContent(
              mockChange: 'left',
              mockUserId: '@user1:acter.global',
            ),
          ),
          'expectedText': 'left',
          'expectedIcon': PhosphorIconsThin.signOut,
        },
        {
          'name': 'membership_invited',
          'widget': (Activity activity) => ActivityMembershipItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.invited.name,
            mockSenderId: '@user1:acter.global',
            mockMembershipContent: MockMembershipContent(
              mockChange: 'invited',
              mockUserId: '@user2:acter.global',
            ),
          ),
          'expectedText': 'invited',
          'expectedIcon': PhosphorIconsThin.userPlus,
        },
        {
          'name': 'membership_banned',
          'widget': (Activity activity) => ActivityMembershipItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.banned.name,
            mockSenderId: '@user1:acter.global',
            mockMembershipContent: MockMembershipContent(
              mockChange: 'banned',
              mockUserId: '@user2:acter.global',
            ),
          ),
          'expectedText': 'banned',
          'expectedIcon': PhosphorIconsThin.userCircleMinus,
        },
        {
          'name': 'membership_kicked',
          'widget': (Activity activity) => ActivityMembershipItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.kicked.name,
            mockSenderId: '@user1:acter.global',
            mockMembershipContent: MockMembershipContent(
              mockChange: 'kicked',
              mockUserId: '@user2:acter.global',
            ),
          ),
          'expectedText': 'kicked',
          'expectedIcon': PhosphorIconsThin.userMinus,
        },
        {
          'name': 'membership_invitation_accepted',
          'widget': (Activity activity) => ActivityMembershipItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.invitationAccepted.name,
            mockSenderId: '@user1:acter.global',
            mockMembershipContent: MockMembershipContent(
              mockChange: 'invitationAccepted',
              mockUserId: '@user1:acter.global',
            ),
          ),
          'expectedText': 'accepted',
          'expectedIcon': PhosphorIconsThin.userCheck,
        },
        {
          'name': 'membership_invitation_rejected',
          'widget': (Activity activity) => ActivityMembershipItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.invitationRejected.name,
            mockSenderId: '@user1:acter.global',
            mockMembershipContent: MockMembershipContent(
              mockChange: 'invitationRejected',
              mockUserId: '@user1:acter.global',
            ),
          ),
          'expectedText': 'rejected',
          'expectedIcon': PhosphorIconsThin.userMinus,
        },
        {
          'name': 'membership_invitation_revoked',
          'widget': (Activity activity) => ActivityMembershipItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.invitationRevoked.name,
            mockSenderId: '@user1:acter.global',
            mockMembershipContent: MockMembershipContent(
              mockChange: 'invitationRevoked',
              mockUserId: '@user2:acter.global',
            ),
          ),
          'expectedText': 'revoked',
          'expectedIcon': PhosphorIconsThin.minusCircle,
        },
        {
          'name': 'membership_knock_accepted',
          'widget': (Activity activity) => ActivityMembershipItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.knockAccepted.name,
            mockSenderId: '@user1:acter.global',
            mockMembershipContent: MockMembershipContent(
              mockChange: 'knockAccepted',
              mockUserId: '@user1:acter.global',
            ),
          ),
          'expectedText': 'accepted',
          'expectedIcon': PhosphorIconsThin.userCheck,
        },
        {
          'name': 'membership_knock_retracted',
          'widget': (Activity activity) => ActivityMembershipItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.knockRetracted.name,
            mockSenderId: '@user1:acter.global',
            mockMembershipContent: MockMembershipContent(
              mockChange: 'knockRetracted',
              mockUserId: '@user1:acter.global',
            ),
          ),
          'expectedText': 'retracted',
          'expectedIcon': PhosphorIconsThin.userCircleMinus,
        },
        {
          'name': 'membership_knock_denied',
          'widget': (Activity activity) => ActivityMembershipItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.knockDenied.name,
            mockSenderId: '@user1:acter.global',
            mockMembershipContent: MockMembershipContent(
              mockChange: 'knockDenied',
              mockUserId: '@user1:acter.global',
            ),
          ),
          'expectedText': 'denied',
          'expectedIcon': PhosphorIconsThin.userCircleMinus,
        },
        {
          'name': 'membership_unbanned',
          'widget': (Activity activity) => ActivityMembershipItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.unbanned.name,
            mockSenderId: '@user1:acter.global',
            mockMembershipContent: MockMembershipContent(
              mockChange: 'unbanned',
              mockUserId: '@user2:acter.global',
            ),
          ),
          'expectedText': 'unbanned',
          'expectedIcon': PhosphorIconsThin.userCirclePlus,
        },
        {
          'name': 'membership_kicked_and_banned',
          'widget': (Activity activity) => ActivityMembershipItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.kickedAndBanned.name,
            mockSenderId: '@user1:acter.global',
            mockMembershipContent: MockMembershipContent(
              mockChange: 'kickedAndBanned',
              mockUserId: '@user2:acter.global',
            ),
          ),
          'expectedText': 'kicked and banned',
          'expectedIcon': PhosphorIconsThin.userCircleMinus,
        },
        {
          'name': 'membership_knocked',
          'widget': (Activity activity) => ActivityMembershipItemWidget(activity: activity),
          'activity': MockActivity(
            mockType: PushStyles.knocked.name,
            mockSenderId: '@user1:acter.global',
            mockMembershipContent: MockMembershipContent(
              mockChange: 'knocked',
              mockUserId: '@user1:acter.global',
            ),
          ),
          'expectedText': 'knocked',
          'expectedIcon': PhosphorIconsThin.userPlus,
        },
      ];

      for (final entry in showcaseTypeWidgets) {
        testWidgets('golden: ${entry['name']}', (WidgetTester tester) async {
          final activity = entry['activity'] as MockActivity;
          final widgetBuilder = entry['widget'] as Widget Function(Activity);
          final expectedIcon = entry['expectedIcon'] as IconData?;

          await createWidgetUnderTest(
            tester: tester,
            widget: widgetBuilder(activity),
            screenshotPath: 'test/features/activity/item_widgets/goldens/${entry['name']}_widget.png',
          );

          // Check for expected icon if specified
          if (expectedIcon != null) {
            expect(find.byIcon(expectedIcon), findsOneWidget);
          }
          
          // For comment widget, also check for the comment content
          if (entry['name'] == 'comment') {
            expect(find.text('Showcase comment!'), findsOneWidget);
          }

          // Check for subtitle if expected
          if (entry['expectedSubtitle'] != null) {
            expect(find.text(entry['expectedSubtitle'] as String), findsOneWidget);
          }
        });
      }
    });
  });
}