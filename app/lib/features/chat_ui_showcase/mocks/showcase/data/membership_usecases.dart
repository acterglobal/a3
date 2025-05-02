import 'package:acter/features/chat_ui_showcase/mocks/convo/mock_membership_content.dart';
import 'package:acter/features/chat_ui_showcase/mocks/convo/timeline/mock_timeline_event_item.dart';
import 'package:acter/features/chat_ui_showcase/mocks/showcase/convo_showcase_data.dart';

final membershipEventjoinedRoom22 = createMockChatItem(
  roomId: 'mock-room-22',
  displayName: 'Moderation',
  activeMembersIds: [
    '@emily:acter.global',
    '@alex:acter.global',
    '@david:acter.global',
  ],
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@emily:acter.global',
      mockOriginServerTs: 1742800566000, // March 24, 2025
      mockEventType: 'MembershipChange',
      mockMembershipContent: MockMembershipContent(
        mockUserId: '@david:acter.global',
        mockMembershipType: 'joined',
      ),
    ),
  ],
);

final membershipEventLeftRoom23 = createMockChatItem(
  roomId: 'mock-room-23',
  displayName: 'General',
  activeMembersIds: ['@emily:acter.global', '@alex:acter.global'],
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@david:acter.global',
      mockOriginServerTs: 1742800567000,
      mockEventType: 'MembershipChange',
      mockMembershipContent: MockMembershipContent(
        mockUserId: '@david:acter.global',
        mockMembershipType: 'left',
      ),
    ),
  ],
);

final membershipEventInvitationAcceptedRoom24 = createMockChatItem(
  roomId: 'mock-room-24',
  displayName: 'Project Alpha',
  activeMembersIds: [
    '@emily:acter.global',
    '@alex:acter.global',
    '@david:acter.global',
  ],
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@david:acter.global',
      mockOriginServerTs: 1742800568000,
      mockEventType: 'MembershipChange',
      mockMembershipContent: MockMembershipContent(
        mockUserId: '@david:acter.global',
        mockMembershipType: 'invitationAccepted',
      ),
    ),
  ],
);

final membershipEventInvitationRejectedRoom25 = createMockChatItem(
  roomId: 'mock-room-25',
  displayName: 'Project Beta',
  activeMembersIds: ['@emily:acter.global', '@alex:acter.global'],
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@david:acter.global',
      mockOriginServerTs: 1742800569000,
      mockEventType: 'MembershipChange',
      mockMembershipContent: MockMembershipContent(
        mockUserId: '@david:acter.global',
        mockMembershipType: 'invitationRejected',
      ),
    ),
  ],
);

final membershipEventInvitationRevokedRoom26 = createMockChatItem(
  roomId: 'mock-room-26',
  displayName: 'Project Gamma',
  activeMembersIds: ['@emily:acter.global', '@alex:acter.global'],
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@emily:acter.global',
      mockOriginServerTs: 1742800570000,
      mockEventType: 'MembershipChange',
      mockMembershipContent: MockMembershipContent(
        mockUserId: '@david:acter.global',
        mockMembershipType: 'invitationRevoked',
      ),
    ),
  ],
);

final membershipEventKnockAcceptedRoom27 = createMockChatItem(
  roomId: 'mock-room-27',
  displayName: 'Private Group',
  activeMembersIds: [
    '@emily:acter.global',
    '@alex:acter.global',
    '@david:acter.global',
  ],
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@emily:acter.global',
      mockOriginServerTs: 1742800571000,
      mockEventType: 'MembershipChange',
      mockMembershipContent: MockMembershipContent(
        mockUserId: '@david:acter.global',
        mockMembershipType: 'knockAccepted',
      ),
    ),
  ],
);

final membershipEventKnockRetractedRoom28 = createMockChatItem(
  roomId: 'mock-room-28',
  displayName: 'Study Group',
  activeMembersIds: ['@emily:acter.global', '@alex:acter.global'],
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@david:acter.global',
      mockOriginServerTs: 1742800572000,
      mockEventType: 'MembershipChange',
      mockMembershipContent: MockMembershipContent(
        mockUserId: '@david:acter.global',
        mockMembershipType: 'knockRetracted',
      ),
    ),
  ],
);

final membershipEventKnockDeniedRoom29 = createMockChatItem(
  roomId: 'mock-room-29',
  displayName: 'Team Meeting',
  activeMembersIds: ['@emily:acter.global', '@alex:acter.global'],
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@emily:acter.global',
      mockOriginServerTs: 1742800573000,
      mockEventType: 'MembershipChange',
      mockMembershipContent: MockMembershipContent(
        mockUserId: '@david:acter.global',
        mockMembershipType: 'knockDenied',
      ),
    ),
  ],
);

final membershipEventBannedRoom30 = createMockChatItem(
  roomId: 'mock-room-30',
  displayName: 'Community',
  activeMembersIds: ['@emily:acter.global', '@alex:acter.global'],
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@emily:acter.global',
      mockOriginServerTs: 1742800574000,
      mockEventType: 'MembershipChange',
      mockMembershipContent: MockMembershipContent(
        mockUserId: '@david:acter.global',
        mockMembershipType: 'banned',
      ),
    ),
  ],
);

final membershipEventUnbannedRoom31 = createMockChatItem(
  roomId: 'mock-room-31',
  displayName: 'Community',
  activeMembersIds: [
    '@emily:acter.global',
    '@alex:acter.global',
    '@david:acter.global',
  ],
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@emily:acter.global',
      mockOriginServerTs: 1742800575000,
      mockEventType: 'MembershipChange',
      mockMembershipContent: MockMembershipContent(
        mockUserId: '@david:acter.global',
        mockMembershipType: 'unbanned',
      ),
    ),
  ],
);

final membershipEventKickedRoom32 = createMockChatItem(
  roomId: 'mock-room-32',
  displayName: 'Team Chat',
  unreadNotificationCount: 1,
  unreadMessages: 1,
  activeMembersIds: ['@emily:acter.global', '@alex:acter.global'],
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@emily:acter.global',
      mockOriginServerTs: 1742800576000,
      mockEventType: 'MembershipChange',
      mockMembershipContent: MockMembershipContent(
        mockUserId: '@david:acter.global',
        mockMembershipType: 'kicked',
      ),
    ),
  ],
);

final membershipEventInvitedRoom33 = createMockChatItem(
  roomId: 'mock-room-33',
  displayName: 'New Project',
  activeMembersIds: ['@emily:acter.global', '@alex:acter.global'],
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@emily:acter.global',
      mockOriginServerTs: 1742800577000,
      mockEventType: 'MembershipChange',
      mockMembershipContent: MockMembershipContent(
        mockUserId: '@david:acter.global',
        mockMembershipType: 'invited',
      ),
    ),
  ],
);

final membershipEventKickedAndBannedRoom34 = createMockChatItem(
  roomId: 'mock-room-34',
  displayName: 'Moderated Room',
  activeMembersIds: ['@emily:acter.global', '@alex:acter.global'],
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@emily:acter.global',
      mockOriginServerTs: 1742800578000,
      mockEventType: 'MembershipChange',
      mockMembershipContent: MockMembershipContent(
        mockUserId: '@david:acter.global',
        mockMembershipType: 'kickedAndBanned',
      ),
    ),
  ],
);

final membershipEventKnockedRoom35 = createMockChatItem(
  roomId: 'mock-room-35',
  displayName: 'Private Room',
  unreadNotificationCount: 1,
  unreadMessages: 1,
  activeMembersIds: ['@emily:acter.global', '@alex:acter.global'],
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@david:acter.global',
      mockOriginServerTs: 1742800579000,
      mockEventType: 'MembershipChange',
      mockMembershipContent: MockMembershipContent(
        mockUserId: '@david:acter.global',
        mockMembershipType: 'knocked',
      ),
    ),
  ],
);
