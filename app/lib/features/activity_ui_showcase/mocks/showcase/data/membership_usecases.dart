import 'package:acter/features/activity_ui_showcase/mocks/general/mock_activity.dart';
import 'package:acter/features/chat_ui_showcase/mocks/convo/mock_membership_content.dart';
import 'package:acter_notifify/model/push_styles.dart';

// Activity ID constants
final joinedEventId = 'joined-activity-membership-1';
final invitationAcceptedEventId = 'invitation-accepted-activity-membership-1';
final invitedEventId = 'invited-activity-membership-1';
final leftEventId = 'left-activity-membership-1';
final invitationRejectedEventId = 'invitation-rejected-activity-membership-1';
final kickedEventId = 'kicked-activity-membership-1';
final bannedEventId = 'banned-activity-membership-1';
final unbannedEventId = 'unbanned-activity-membership-1';
final knockAcceptedEventId = 'knock-accepted-activity-membership-1';
final knockRetractedEventId = 'knock-retracted-activity-membership-1';
final knockDeniedEventId = 'knock-denied-activity-membership-1';

final now = DateTime.now();

final joinedActivity1 = ActivityMock(
  mockEventId: joinedEventId,
  mockType: PushStyles.joined.name,
  mockSubType: 'membership_change',
  mockSenderId: 'sam',
  mockRoomId: 'project-alpha',
  mockOriginServerTs:
      now.subtract(const Duration(days: 1)).millisecondsSinceEpoch,
  mockMembershipContent: MockMembershipContent(
    mockMembershipType: 'joined',
    mockUserId: 'sam',
  ),
);

final invitationAcceptedActivity1 = ActivityMock(
  mockEventId: invitationAcceptedEventId,
  mockType: PushStyles.invitationAccepted.name,
  mockSubType: 'invitation_response',
  mockSenderId: 'tina',
  mockRoomId: 'project-alpha',
  mockOriginServerTs:
      now.subtract(const Duration(days: 1, hours: 2)).millisecondsSinceEpoch,
  mockMembershipContent: MockMembershipContent(
    mockMembershipType: 'invitationAccepted',
    mockUserId: 'tina',
  ),
);

final invitedActivity1 = ActivityMock(
  mockEventId: invitedEventId,
  mockType: PushStyles.invited.name,
  mockSubType: 'invitation_sent',
  mockSenderId: 'uma',
  mockRoomId: 'project-alpha',
  mockOriginServerTs:
      now.subtract(const Duration(days: 1, hours: 4)).millisecondsSinceEpoch,
  mockMembershipContent: MockMembershipContent(
    mockMembershipType: 'invited',
    mockUserId: 'victor',
  ),
);

final leftActivity1 = ActivityMock(
  mockEventId: leftEventId,
  mockType: PushStyles.left.name,
  mockSubType: 'membership_change',
  mockSenderId: 'wendy',
  mockRoomId: 'project-alpha',
  mockOriginServerTs:
      now.subtract(const Duration(days: 2)).millisecondsSinceEpoch,
  mockMembershipContent: MockMembershipContent(
    mockMembershipType: 'left',
    mockUserId: 'wendy',
  ),
);

final invitationRejectedActivity1 = ActivityMock(
  mockEventId: invitationRejectedEventId,
  mockType: PushStyles.invitationRejected.name,
  mockSubType: 'invitation_response',
  mockSenderId: 'xavier',
  mockRoomId: 'project-alpha',
  mockOriginServerTs:
      now.subtract(const Duration(days: 2, hours: 2)).millisecondsSinceEpoch,
  mockMembershipContent: MockMembershipContent(
    mockMembershipType: 'invitationRejected',
    mockUserId: 'xavier',
  ),
);

final kickedActivity1 = ActivityMock(
  mockEventId: kickedEventId,
  mockType: PushStyles.kicked.name,
  mockSubType: 'membership_change',
  mockSenderId: 'yara',
  mockRoomId: 'project-alpha',
  mockOriginServerTs: now.subtract(const Duration(minutes: 26)).millisecondsSinceEpoch,
  mockMembershipContent: MockMembershipContent(
    mockMembershipType: 'kicked',
    mockUserId: 'aara',
  ),
);

final bannedActivity1 = ActivityMock(
  mockEventId: bannedEventId,
  mockType: PushStyles.banned.name,
  mockSubType: 'membership_change',
  mockSenderId: 'zara',
  mockRoomId: 'project-alpha',
  mockOriginServerTs: now.subtract(const Duration(minutes: 27)).millisecondsSinceEpoch,
  mockMembershipContent: MockMembershipContent(
    mockMembershipType: 'banned',
    mockUserId: 'aara',
  ),
);

final unbannedActivity1 = ActivityMock(
  mockEventId: unbannedEventId,
  mockType: PushStyles.unbanned.name,
  mockSubType: 'membership_change',
  mockSenderId: 'zara',
  mockRoomId: 'project-alpha',
  mockOriginServerTs: now.subtract(const Duration(minutes: 28)).millisecondsSinceEpoch,
  mockMembershipContent: MockMembershipContent(
    mockMembershipType: 'unbanned',
    mockUserId: 'aara',
  ),
);

final knockAcceptedActivity1 = ActivityMock(
  mockEventId: knockAcceptedEventId,
  mockType: PushStyles.knockAccepted.name,
  mockSubType: 'membership_change',
  mockSenderId: 'zara',
  mockRoomId: 'project-alpha',
  mockOriginServerTs: now.subtract(const Duration(minutes: 29)).millisecondsSinceEpoch,
  mockMembershipContent: MockMembershipContent(
    mockMembershipType: 'knockAccepted',
    mockUserId: 'aara',
  ),
);

final knockRetractedActivity1 = ActivityMock(
  mockEventId: knockRetractedEventId,
  mockType: PushStyles.knockRetracted.name,
  mockSubType: 'membership_change',
  mockSenderId: 'zara',
  mockRoomId: 'project-alpha',
  mockOriginServerTs: now.subtract(const Duration(minutes: 30)).millisecondsSinceEpoch,
  mockMembershipContent: MockMembershipContent(
    mockMembershipType: 'knockRetracted',
    mockUserId: 'aara',
  ),
);

final knockDeniedActivity1 = ActivityMock(
  mockEventId: knockDeniedEventId,
  mockType: PushStyles.knockDenied.name,
  mockSubType: 'membership_change',
  mockSenderId: 'zara',
  mockRoomId: 'project-alpha',
  mockOriginServerTs: now.subtract(const Duration(minutes: 31)).millisecondsSinceEpoch,
  mockMembershipContent: MockMembershipContent(
    mockMembershipType: 'knockDenied',
    mockUserId: 'aara',
  ),
);