import 'package:acter/features/chat_ui_showcase/models/mocks/showcase_data/chat_event_showcase_list.dart';
import 'package:acter/features/chat_ui_showcase/models/mocks/convo/mock_convo.dart';
import 'package:acter/features/chat_ui_showcase/models/mocks/room/mock_room.dart';
import 'package:acter/features/chat_ui_showcase/models/mocks/timeline/mock_timeline_stream.dart';
import 'package:acter/features/chat_ui_showcase/models/mocks/user/mock_user.dart';

class MockChatItem {
  final String roomId;
  final MockRoom mockRoom;
  final MockConvo mockConvo;
  final List<MockUser>? typingUsers;

  MockChatItem({
    required this.roomId,
    required this.mockRoom,
    required this.mockConvo,
    required this.typingUsers,
  });
}

MockChatItem createMockChatItem({
  required String roomId,
  required String displayName,
  String? notificationMode,
  List<String>? activeMembersIds,
  bool? isDm,
  bool? isBookmarked,
  int? unreadNotificationCount,
  int? unreadMentions,
  int? unreadMessages,
  List<MockUser>? typingUsers,
  MockTimelineEventItem? timelineEventItem,
}) {
  return MockChatItem(
    roomId: roomId,
    typingUsers: typingUsers,
    mockRoom: MockRoom(
      mockRoomId: roomId,
      mockDisplayName: displayName,
      mockNotificationMode: notificationMode ?? 'all',
      mockActiveMembersIds: activeMembersIds ?? [],
    ),
    mockConvo: MockConvo(
      mockConvoId: roomId,
      mockIsDm: isDm ?? false,
      mockIsBookmarked: isBookmarked ?? false,
      mockNumUnreadNotificationCount: unreadNotificationCount ?? 0,
      mockNumUnreadMentions: unreadMentions ?? 0,
      mockNumUnreadMessages: unreadMessages ?? 0,
      mockTimelineItem: MockTimelineItem(
        mockTimelineEventItem: timelineEventItem,
      ),
      mockTimelineStream: MockTimelineStream(
        mockTimelineItemDiffs: [
          MockTimelineItemDiff(
            mockAction: 'Append',
            mockTimelineItemList: MockFfiListTimelineItem(
              timelineItems: mockChatEventList,
            ),
            mockIndex: 0,
            mockTimelineItem: MockTimelineItem(
              mockTimelineEventItem: timelineEventItem,
            ),
          ),
        ],
      ),
    ),
  );
}

final emilyDmMutedBookmarkedRoom1 = createMockChatItem(
  roomId: 'mock-room-1',
  displayName: 'Emily Davis',
  notificationMode: 'muted',
  activeMembersIds: ['@emily:acter.global', '@david:acter.global'],
  isDm: true,
  isBookmarked: true,
  unreadNotificationCount: 4,
  unreadMentions: 2,
  unreadMessages: 2,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@emily:acter.global',
    mockOriginServerTs: 1744182966000, // April 9, 2025
    mockMsgContent: MockMsgContent(mockBody: 'Hey, whats the update?'),
  ),
);

final productTeamMutedWithSingleTypingUserRoom2 = createMockChatItem(
  roomId: 'mock-room-2',
  displayName: 'Product Team',
  notificationMode: 'muted',
  activeMembersIds: [
    '@sarah:acter.global',
    '@michael:acter.global',
    '@lisa:acter.global',
    '@alex:acter.global',
  ],
  unreadNotificationCount: 2,
  unreadMessages: 2,
  typingUsers: [MockUser(mockDisplayName: 'Emily')],
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@sarah:acter.global',
    mockOriginServerTs: 1744096566000, // April 8, 2025
    mockMsgContent: MockMsgContent(
      mockBody: 'Deployment tomorrow at 2 PM. Review checklist.',
    ),
  ),
);

final engineeringTeamWithTestUpdateRoom3 = createMockChatItem(
  roomId: 'mock-room-3',
  displayName: 'Engineering',
  activeMembersIds: [
    '@robert:acter.global',
    '@jennifer:acter.global',
    '@david:acter.global',
    '@patricia:acter.global',
  ],
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@robert:acter.global',
    mockOriginServerTs: 1744010166000, // April 7, 2025
    mockMsgContent: MockMsgContent(mockBody: 'CI/CD fixed. Tests passing.'),
  ),
);

final designReviewMutedBookmarkedWithUnreadRoom4 = createMockChatItem(
  roomId: 'mock-room-4',
  displayName: 'Design Review',
  notificationMode: 'muted',
  unreadNotificationCount: 2,
  unreadMessages: 2,
  activeMembersIds: [
    '@emma:acter.global',
    '@christopher:acter.global',
    '@daniel:acter.global',
    '@james:acter.global',
  ],
  isBookmarked: true,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@emma:acter.global',
    mockOriginServerTs: 1743923766000, // April 6, 2025
    mockMsgContent: MockMsgContent(
      mockBody: 'UI components updated. Please review.',
    ),
  ),
);

final groupDmWithMichaelKumarpalsinhBenRoom5 = createMockChatItem(
  roomId: 'mock-room-5',
  displayName: 'Michael, Kumarpalsinh & Ben',
  activeMembersIds: [
    '@michael:acter.global',
    '@kumarpalsinh:acter.global',
    '@ben:acter.global',
  ],
  isDm: true,
  isBookmarked: true,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@michael:acter.global',
    mockOriginServerTs: 1743837366000, // April 5, 2025
    mockMsgContent: MockMsgContent(
      mockBody: 'Can we schedule a quick sync about the API changes?',
    ),
  ),
);

final sarahDmWithTypingRoom6 = createMockChatItem(
  roomId: 'mock-room-6',
  displayName: 'Sarah Wilson',
  activeMembersIds: ['@sarah:acter.global', '@kumarpalsinh:acter.global'],
  isDm: true,
  typingUsers: [MockUser(mockDisplayName: 'Sarah')],
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@sarah:acter.global',
    mockOriginServerTs: 1743750966000, // April 4, 2025
    mockMsgContent: MockMsgContent(
      mockBody:
          'The meeting notes are ready. I\'ve highlighted the action items.',
    ),
  ),
);

final projectAlphaWithMultipleTypingRoom7 = createMockChatItem(
  roomId: 'mock-room-7',
  displayName: 'Project Alpha',
  typingUsers: [
    MockUser(mockDisplayName: 'Jennifer'),
    MockUser(mockDisplayName: 'James'),
    MockUser(mockDisplayName: 'David'),
  ],
  activeMembersIds: [
    '@jennifer:acter.global',
    '@james:acter.global',
    '@patricia:acter.global',
    '@david:acter.global',
  ],
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@jennifer:acter.global',
    mockOriginServerTs: 1743664566000, // April 3, 2025
    mockMsgContent: MockMsgContent(mockBody: 'Sprint retro tomorrow at 11 AM.'),
  ),
);

final lisaDmBookmarkedImageMessageRoom8 = createMockChatItem(
  roomId: 'mock-room-8',
  displayName: 'Lisa Park',
  activeMembersIds: ['@lisa:acter.global', '@kumarpalsinh:acter.global'],
  isDm: true,
  isBookmarked: true,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@lisa:acter.global',
    mockOriginServerTs: 1743578166000, // April 2, 2025
    mockMsgContent: MockMsgContent(
      mockBody: 'The documentation is updated with the latest API changes.',
    ),
  ),
);

final teamUpdatesBookmarkedVideoMessageRoom9 = createMockChatItem(
  roomId: 'mock-room-9',
  displayName: 'Team Updates',
  activeMembersIds: [
    '@emily:acter.global',
    '@alex:acter.global',
    '@christopher:acter.global',
    '@daniel:acter.global',
  ],
  isBookmarked: true,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@emily:acter.global',
    mockOriginServerTs: 1743491766000, // April 1, 2025
    mockMsgContent: MockMsgContent(
      mockBody: 'New features deployed. Monitor for issues.',
    ),
  ),
);

final groupDmWithEmmaKumarpalsinhBenRoom10 = createMockChatItem(
  roomId: 'mock-room-10',
  displayName: 'Emma, Kumarpalsinh & Ben',
  activeMembersIds: [
    '@emma:acter.global',
    '@kumarpalsinh:acter.global',
    '@ben:acter.global',
  ],
  isDm: true,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@emma:acter.global',
    mockOriginServerTs: 1743405366000, // March 31, 2025
    mockMsgContent: MockMsgContent(
      mockBody:
          'Let me know when you\'re free to discuss the design system updates.',
    ),
  ),
);

final alexDmRoom11 = createMockChatItem(
  roomId: 'mock-room-11',
  displayName: 'Alex Thompson',
  activeMembersIds: ['@alex:acter.global', '@kumarpalsinh:acter.global'],
  isDm: true,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@alex:acter.global',
    mockOriginServerTs: 1743318966000, // March 30, 2025
    mockMsgContent: MockMsgContent(
      mockBody: 'See you at the team meeting tomorrow at 10 AM.',
    ),
  ),
);

final marketingTeamRoom12 = createMockChatItem(
  roomId: 'mock-room-12',
  displayName: 'Marketing Team',
  activeMembersIds: [
    '@christopher:acter.global',
    '@daniel:acter.global',
    '@james:acter.global',
    '@patricia:acter.global',
  ],
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@christopher:acter.global',
    mockOriginServerTs: 1743232566000, // March 29, 2025
    mockMsgContent: MockMsgContent(
      mockBody: 'Campaign approved. Launch next week.',
    ),
  ),
);

final lisaDmRoom13 = createMockChatItem(
  roomId: 'mock-room-13',
  displayName: 'Lisa Park',
  activeMembersIds: ['@lisa:acter.global', '@kumarpalsinh:acter.global'],
  isDm: true,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@lisa:acter.global',
    mockOriginServerTs: 1743146166000, // March 28, 2025
    mockMsgContent: MockMsgContent(
      mockBody: 'Document reviewed and approved. Ready for implementation.',
    ),
  ),
);

final productFeedbackGroupRoom14 = createMockChatItem(
  roomId: 'mock-room-14',
  displayName: 'Product Feedback',
  activeMembersIds: [
    '@daniel:acter.global',
    '@james:acter.global',
    '@patricia:acter.global',
    '@david:acter.global',
  ],
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@daniel:acter.global',
    mockOriginServerTs: 1743059766000, // March 27, 2025
    mockMsgContent: MockMsgContent(mockBody: 'Feature requests prioritized.'),
  ),
);

final davidDmRoom15 = createMockChatItem(
  roomId: 'mock-room-15',
  displayName: 'David Miller',
  activeMembersIds: ['@david:acter.global', '@kumarpalsinh:acter.global'],
  isDm: true,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@david:acter.global',
    mockOriginServerTs: 1742973366000, // March 26, 2025
    mockMsgContent: MockMsgContent(
      mockBody: 'Task completed and merged to main branch.',
    ),
  ),
);

final imageMessageDmRoom16 = createMockChatItem(
  roomId: 'mock-room-16',
  displayName: 'Meeko',
  activeMembersIds: ['@meeko:acter.global', '@kumarpalsinh:acter.global'],
  isDm: true,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@meeko:acter.global',
    mockOriginServerTs: 1743318966000, // March 30, 2025
    mockMsgType: 'm.image',
    mockEventType: 'm.room.message',
    mockMsgContent: MockMsgContent(
      mockBody: 'Image message about the API changes',
    ),
  ),
);

final videoMessageDmRoom17 = createMockChatItem(
  roomId: 'mock-room-17',
  displayName: 'Sales Team',
  unreadNotificationCount: 2,
  unreadMessages: 2,
  activeMembersIds: [
    '@emily:acter.global',
    '@alex:acter.global',
    '@christopher:acter.global',
    '@daniel:acter.global',
    '@james:acter.global',
    '@patricia:acter.global',
  ],
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@david:acter.global',
    mockOriginServerTs: 1743318966000, // March 30, 2025
    mockMsgType: 'm.video',
    mockEventType: 'm.room.message',
    mockMsgContent: MockMsgContent(
      mockBody: 'Video message about the API changes',
    ),
  ),
);

final audioMessageDmRoom18 = createMockChatItem(
  roomId: 'mock-room-18',
  displayName: 'Max Leon',
  activeMembersIds: ['@maxleon:acter.global', '@kumarpalsinh:acter.global'],
  isDm: true,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@maxleon:acter.global',
    mockOriginServerTs: 1743318966000, // March 30, 2025
    mockMsgType: 'm.audio',
    mockEventType: 'm.room.message',
    mockMsgContent: MockMsgContent(
      mockBody: 'Voice message about the API changes',
    ),
  ),
);

final fileMessageDmRoom19 = createMockChatItem(
  roomId: 'mock-room-19',
  displayName: 'Jennifer Lee',
  activeMembersIds: ['@jennifer:acter.global', '@kumarpalsinh:acter.global'],
  isDm: true,
  isBookmarked: true,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@jennifer:acter.global',
    mockOriginServerTs: 1743232566000, // March 29, 2025
    mockMsgType: 'm.file',
    mockEventType: 'm.room.message',
    mockMsgContent: MockMsgContent(mockBody: 'Project proposal document'),
  ),
);

final locationMessageDmRoom20 = createMockChatItem(
  roomId: 'mock-room-20',
  displayName: 'Design Team',
  unreadNotificationCount: 5,
  unreadMessages: 5,
  activeMembersIds: [
    '@michael:acter.global',
    '@kumarpalsinh:acter.global',
    '@emily:acter.global',
    '@alex:acter.global',
    '@david:acter.global',
  ],
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@michael:acter.global',
    mockOriginServerTs: 1743146166000, // March 28, 2025
    mockMsgType: 'm.location',
    mockEventType: 'm.room.message',
    mockMsgContent: MockMsgContent(mockBody: 'Meeting location'),
  ),
);

final redactionEventRoom21 = createMockChatItem(
  roomId: 'mock-room-21',
  displayName: 'Moderation',
  activeMembersIds: [
    '@emily:acter.global',
    '@alex:acter.global',
    '@david:acter.global',
  ],
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@emily:acter.global',
    mockOriginServerTs: 1742800566000, // March 24, 2025
    mockEventType: 'm.room.redaction',
    mockMsgContent: MockMsgContent(mockBody: 'Message was redacted'),
  ),
);

final membershipEventjoinedRoom22 = createMockChatItem(
  roomId: 'mock-room-22',
  displayName: 'Moderation',
  activeMembersIds: [
    '@emily:acter.global',
    '@alex:acter.global',
    '@david:acter.global',
  ],
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@emily:acter.global',
    mockOriginServerTs: 1742800566000, // March 24, 2025
    mockEventType: 'MembershipChange',
    mockMembershipContent: MockMembershipContent(
      mockUserId: '@david:acter.global',
      mockMembershipType: 'joined',
    ),
  ),
);

final membershipEventLeftRoom23 = createMockChatItem(
  roomId: 'mock-room-23',
  displayName: 'General',
  activeMembersIds: ['@emily:acter.global', '@alex:acter.global'],
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@david:acter.global',
    mockOriginServerTs: 1742800567000,
    mockEventType: 'MembershipChange',
    mockMembershipContent: MockMembershipContent(
      mockUserId: '@david:acter.global',
      mockMembershipType: 'left',
    ),
  ),
);

final membershipEventInvitationAcceptedRoom24 = createMockChatItem(
  roomId: 'mock-room-24',
  displayName: 'Project Alpha',
  activeMembersIds: [
    '@emily:acter.global',
    '@alex:acter.global',
    '@david:acter.global',
  ],
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@david:acter.global',
    mockOriginServerTs: 1742800568000,
    mockEventType: 'MembershipChange',
    mockMembershipContent: MockMembershipContent(
      mockUserId: '@david:acter.global',
      mockMembershipType: 'invitationAccepted',
    ),
  ),
);

final membershipEventInvitationRejectedRoom25 = createMockChatItem(
  roomId: 'mock-room-25',
  displayName: 'Project Beta',
  activeMembersIds: ['@emily:acter.global', '@alex:acter.global'],
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@david:acter.global',
    mockOriginServerTs: 1742800569000,
    mockEventType: 'MembershipChange',
    mockMembershipContent: MockMembershipContent(
      mockUserId: '@david:acter.global',
      mockMembershipType: 'invitationRejected',
    ),
  ),
);

final membershipEventInvitationRevokedRoom26 = createMockChatItem(
  roomId: 'mock-room-26',
  displayName: 'Project Gamma',
  activeMembersIds: ['@emily:acter.global', '@alex:acter.global'],
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@emily:acter.global',
    mockOriginServerTs: 1742800570000,
    mockEventType: 'MembershipChange',
    mockMembershipContent: MockMembershipContent(
      mockUserId: '@david:acter.global',
      mockMembershipType: 'invitationRevoked',
    ),
  ),
);

final membershipEventKnockAcceptedRoom27 = createMockChatItem(
  roomId: 'mock-room-27',
  displayName: 'Private Group',
  activeMembersIds: [
    '@emily:acter.global',
    '@alex:acter.global',
    '@david:acter.global',
  ],
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@emily:acter.global',
    mockOriginServerTs: 1742800571000,
    mockEventType: 'MembershipChange',
    mockMembershipContent: MockMembershipContent(
      mockUserId: '@david:acter.global',
      mockMembershipType: 'knockAccepted',
    ),
  ),
);

final membershipEventKnockRetractedRoom28 = createMockChatItem(
  roomId: 'mock-room-28',
  displayName: 'Study Group',
  activeMembersIds: ['@emily:acter.global', '@alex:acter.global'],
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@david:acter.global',
    mockOriginServerTs: 1742800572000,
    mockEventType: 'MembershipChange',
    mockMembershipContent: MockMembershipContent(
      mockUserId: '@david:acter.global',
      mockMembershipType: 'knockRetracted',
    ),
  ),
);

final membershipEventKnockDeniedRoom29 = createMockChatItem(
  roomId: 'mock-room-29',
  displayName: 'Team Meeting',
  activeMembersIds: ['@emily:acter.global', '@alex:acter.global'],
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@emily:acter.global',
    mockOriginServerTs: 1742800573000,
    mockEventType: 'MembershipChange',
    mockMembershipContent: MockMembershipContent(
      mockUserId: '@david:acter.global',
      mockMembershipType: 'knockDenied',
    ),
  ),
);

final membershipEventBannedRoom30 = createMockChatItem(
  roomId: 'mock-room-30',
  displayName: 'Community',
  activeMembersIds: ['@emily:acter.global', '@alex:acter.global'],
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@emily:acter.global',
    mockOriginServerTs: 1742800574000,
    mockEventType: 'MembershipChange',
    mockMembershipContent: MockMembershipContent(
      mockUserId: '@david:acter.global',
      mockMembershipType: 'banned',
    ),
  ),
);

final membershipEventUnbannedRoom31 = createMockChatItem(
  roomId: 'mock-room-31',
  displayName: 'Community',
  activeMembersIds: [
    '@emily:acter.global',
    '@alex:acter.global',
    '@david:acter.global',
  ],
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@emily:acter.global',
    mockOriginServerTs: 1742800575000,
    mockEventType: 'MembershipChange',
    mockMembershipContent: MockMembershipContent(
      mockUserId: '@david:acter.global',
      mockMembershipType: 'unbanned',
    ),
  ),
);

final membershipEventKickedRoom32 = createMockChatItem(
  roomId: 'mock-room-32',
  displayName: 'Team Chat',
  unreadNotificationCount: 1,
  unreadMessages: 1,
  activeMembersIds: ['@emily:acter.global', '@alex:acter.global'],
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@emily:acter.global',
    mockOriginServerTs: 1742800576000,
    mockEventType: 'MembershipChange',
    mockMembershipContent: MockMembershipContent(
      mockUserId: '@david:acter.global',
      mockMembershipType: 'kicked',
    ),
  ),
);

final membershipEventInvitedRoom33 = createMockChatItem(
  roomId: 'mock-room-33',
  displayName: 'New Project',
  activeMembersIds: ['@emily:acter.global', '@alex:acter.global'],
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@emily:acter.global',
    mockOriginServerTs: 1742800577000,
    mockEventType: 'MembershipChange',
    mockMembershipContent: MockMembershipContent(
      mockUserId: '@david:acter.global',
      mockMembershipType: 'invited',
    ),
  ),
);

final membershipEventKickedAndBannedRoom34 = createMockChatItem(
  roomId: 'mock-room-34',
  displayName: 'Moderated Room',
  activeMembersIds: ['@emily:acter.global', '@alex:acter.global'],
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@emily:acter.global',
    mockOriginServerTs: 1742800578000,
    mockEventType: 'MembershipChange',
    mockMembershipContent: MockMembershipContent(
      mockUserId: '@david:acter.global',
      mockMembershipType: 'kickedAndBanned',
    ),
  ),
);

final membershipEventKnockedRoom35 = createMockChatItem(
  roomId: 'mock-room-35',
  displayName: 'Private Room',
  unreadNotificationCount: 1,
  unreadMessages: 1,
  activeMembersIds: ['@emily:acter.global', '@alex:acter.global'],
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@david:acter.global',
    mockOriginServerTs: 1742800579000,
    mockEventType: 'MembershipChange',
    mockMembershipContent: MockMembershipContent(
      mockUserId: '@david:acter.global',
      mockMembershipType: 'knocked',
    ),
  ),
);

final profileEventDisplayNameChangedRoom36 = createMockChatItem(
  roomId: 'mock-room-36',
  displayName: 'Profile Changes',
  activeMembersIds: ['@emily:acter.global', '@david:acter.global'],
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@david:acter.global',
    mockOriginServerTs: 1742800580000,
    mockEventType: 'ProfileChange',
    mockProfileContent: MockProfileContent(
      mockUserId: '@david:acter.global',
      mockDisplayNameChange: 'Changed',
      mockDisplayNameOldVal: 'David Miller',
      mockDisplayNameNewVal: 'David M.',
    ),
  ),
);

final profileEventDisplayNameSetRoom37 = createMockChatItem(
  roomId: 'mock-room-37',
  displayName: 'Profile Updates',
  activeMembersIds: ['@emily:acter.global', '@david:acter.global'],
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@david:acter.global',
    mockOriginServerTs: 1742800581000,
    mockEventType: 'ProfileChange',
    mockProfileContent: MockProfileContent(
      mockUserId: '@david:acter.global',
      mockDisplayNameChange: 'Set',
      mockDisplayNameNewVal: 'David Miller',
    ),
  ),
);

final profileEventDisplayNameUnsetRoom38 = createMockChatItem(
  roomId: 'mock-room-38',
  displayName: 'Profile Management',
  activeMembersIds: ['@emily:acter.global', '@david:acter.global'],
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@david:acter.global',
    mockOriginServerTs: 1742800582000,
    mockEventType: 'ProfileChange',
    mockProfileContent: MockProfileContent(
      mockUserId: '@david:acter.global',
      mockDisplayNameChange: 'Unset',
    ),
  ),
);

final profileEventAvatarChangedRoom39 = createMockChatItem(
  roomId: 'mock-room-39',
  displayName: 'Avatar Updates',
  activeMembersIds: ['@emily:acter.global', '@david:acter.global'],
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@david:acter.global',
    mockOriginServerTs: 1742800583000,
    mockEventType: 'ProfileChange',
    mockProfileContent: MockProfileContent(
      mockUserId: '@david:acter.global',
      mockAvatarUrlChange: 'Changed',
    ),
  ),
);

final profileEventAvatarSetRoom40 = createMockChatItem(
  roomId: 'mock-room-40',
  displayName: 'Avatar Management',
  activeMembersIds: ['@emily:acter.global', '@david:acter.global'],
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@david:acter.global',
    mockOriginServerTs: 1742800584000,
    mockEventType: 'ProfileChange',
    mockProfileContent: MockProfileContent(
      mockUserId: '@david:acter.global',
      mockAvatarUrlChange: 'Set',
    ),
  ),
);

final profileEventAvatarUnsetRoom41 = createMockChatItem(
  roomId: 'mock-room-41',
  displayName: 'Profile Cleanup',
  activeMembersIds: ['@emily:acter.global', '@david:acter.global'],
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@david:acter.global',
    mockOriginServerTs: 1742800585000,
    mockEventType: 'ProfileChange',
    mockProfileContent: MockProfileContent(
      mockUserId: '@david:acter.global',
      mockAvatarUrlChange: 'Unset',
    ),
  ),
);
