import 'package:acter/features/chat_ui_showcase/models/mock_convo.dart';
import 'package:acter/features/chat_ui_showcase/models/mock_room.dart';

class MockChatItem {
  final String roomId;
  final MockRoom mockRoom;
  final MockConvo mockConvo;

  MockChatItem({
    required this.roomId,
    required this.mockRoom,
    required this.mockConvo,
  });
}

MockChatItem createMockChatItem({
  required String roomId,
  required String displayName,
  required String notificationMode,
  required List<String> activeMembersIds,
  required bool isDm,
  required bool isBookmarked,
  required int unreadNotificationCount,
  required int unreadMentions,
  required int unreadMessages,
  required MockTimelineEventItem timelineEventItem,
}) {
  return MockChatItem(
    roomId: roomId,
    mockRoom: MockRoom(
      mockRoomId: roomId,
      mockDisplayName: displayName,
      mockNotificationMode: notificationMode,
      mockActiveMembersIds: activeMembersIds,
    ),
    mockConvo: MockConvo(
      mockConvoId: roomId,
      mockIsDm: isDm,
      mockIsBookmarked: isBookmarked,
      mockNumUnreadNotificationCount: unreadNotificationCount,
      mockNumUnreadMentions: unreadMentions,
      mockNumUnreadMessages: unreadMessages,
      mockTimelineItem: MockTimelineItem(
        mockTimelineEventItem: timelineEventItem,
      ),
    ),
  );
}

final mockChatItem1 = createMockChatItem(
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
    mockOriginServerTs: 1710000000000, // March 7, 2024
    mockMsgContent: MockMsgContent(
      mockBody: 'Hey, did you get a chance to review the design mockups?',
    ),
  ),
);

final mockChatItem2 = createMockChatItem(
  roomId: 'mock-room-2',
  displayName: 'Product Team',
  notificationMode: 'muted',
  activeMembersIds: [
    '@sarah:acter.global',
    '@michael:acter.global',
    '@lisa:acter.global',
    '@alex:acter.global',
  ],
  isDm: false,
  isBookmarked: false,
  unreadNotificationCount: 2,
  unreadMentions: 0,
  unreadMessages: 2,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@sarah:acter.global',
    mockOriginServerTs: 1709900000000, // March 6, 2024
    mockMsgContent: MockMsgContent(
      mockBody:
          'The new feature deployment is scheduled for tomorrow at 2 PM. Please review the checklist.',
    ),
  ),
);

final mockChatItem3 = createMockChatItem(
  roomId: 'mock-room-3',
  displayName: 'Engineering',
  notificationMode: 'all',
  activeMembersIds: [
    '@robert:acter.global',
    '@jennifer:acter.global',
    '@david:acter.global',
    '@patricia:acter.global',
  ],
  isDm: false,
  isBookmarked: false,
  unreadNotificationCount: 2,
  unreadMentions: 0,
  unreadMessages: 2,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@robert:acter.global',
    mockOriginServerTs: 1709800000000, // March 5, 2024
    mockMsgContent: MockMsgContent(
      mockBody: 'The CI/CD pipeline is now fixed. All tests are passing.',
    ),
  ),
);

final mockChatItem4 = createMockChatItem(
  roomId: 'mock-room-4',
  displayName: 'Design Review',
  notificationMode: 'muted',
  activeMembersIds: [
    '@emma:acter.global',
    '@christopher:acter.global',
    '@daniel:acter.global',
    '@james:acter.global',
  ],
  isDm: false,
  isBookmarked: true,
  unreadNotificationCount: 0,
  unreadMentions: 0,
  unreadMessages: 0,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@emma:acter.global',
    mockOriginServerTs: 1709700000000, // March 4, 2024
    mockMsgContent: MockMsgContent(
      mockBody:
          'I\'ve updated the UI components based on the feedback. Please review the latest version.',
    ),
  ),
);

final mockChatItem5 = createMockChatItem(
  roomId: 'mock-room-5',
  displayName: 'Michael, Kumarpalsinh & Ben',
  notificationMode: 'all',
  activeMembersIds: [
    '@michael:acter.global',
    '@kumarpalsinh:acter.global',
    '@ben:acter.global',
  ],
  isDm: true,
  isBookmarked: false,
  unreadNotificationCount: 0,
  unreadMentions: 0,
  unreadMessages: 0,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@michael:acter.global',
    mockOriginServerTs: 1709600000000, // March 3, 2024
    mockMsgContent: MockMsgContent(
      mockBody: 'Can we schedule a quick sync about the API changes?',
    ),
  ),
);

final mockChatItem6 = createMockChatItem(
  roomId: 'mock-room-6',
  displayName: 'Sarah Wilson',
  notificationMode: 'all',
  activeMembersIds: ['@sarah:acter.global', '@kumarpalsinh:acter.global'],
  isDm: true,
  isBookmarked: false,
  unreadNotificationCount: 0,
  unreadMentions: 0,
  unreadMessages: 0,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@sarah:acter.global',
    mockOriginServerTs: 1709500000000, // March 2, 2024
    mockMsgContent: MockMsgContent(
      mockBody:
          'The meeting notes are ready. I\'ve highlighted the action items.',
    ),
  ),
);

final mockChatItem7 = createMockChatItem(
  roomId: 'mock-room-7',
  displayName: 'Project Alpha',
  notificationMode: 'all',
  activeMembersIds: [
    '@jennifer:acter.global',
    '@james:acter.global',
    '@patricia:acter.global',
    '@david:acter.global',
  ],
  isDm: false,
  isBookmarked: false,
  unreadNotificationCount: 0,
  unreadMentions: 0,
  unreadMessages: 0,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@jennifer:acter.global',
    mockOriginServerTs: 1709400000000, // March 1, 2024
    mockMsgContent: MockMsgContent(
      mockBody: 'The sprint retrospective is scheduled for tomorrow at 11 AM.',
    ),
  ),
);

final mockChatItem8 = createMockChatItem(
  roomId: 'mock-room-8',
  displayName: 'Lisa Park',
  notificationMode: 'all',
  activeMembersIds: ['@lisa:acter.global', '@kumarpalsinh:acter.global'],
  isDm: true,
  isBookmarked: true,
  unreadNotificationCount: 0,
  unreadMentions: 0,
  unreadMessages: 0,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@lisa:acter.global',
    mockOriginServerTs: 1709300000000, // February 29, 2024
    mockMsgContent: MockMsgContent(
      mockBody: 'The documentation is updated with the latest API changes.',
    ),
  ),
);

final mockChatItem9 = createMockChatItem(
  roomId: 'mock-room-9',
  displayName: 'Team Updates',
  notificationMode: 'all',
  activeMembersIds: [
    '@emily:acter.global',
    '@alex:acter.global',
    '@christopher:acter.global',
    '@daniel:acter.global',
  ],
  isDm: false,
  isBookmarked: true,
  unreadNotificationCount: 0,
  unreadMentions: 0,
  unreadMessages: 0,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@emily:acter.global',
    mockOriginServerTs: 1709200000000, // February 28, 2024
    mockMsgContent: MockMsgContent(
      mockBody:
          'New features deployed to production. Please monitor for any issues.',
    ),
  ),
);

final mockChatItem10 = createMockChatItem(
  roomId: 'mock-room-10',
  displayName: 'Emma, Kumarpalsinh & Ben',
  notificationMode: 'all',
  activeMembersIds: [
    '@emma:acter.global',
    '@kumarpalsinh:acter.global',
    '@ben:acter.global',
  ],
  isDm: true,
  isBookmarked: false,
  unreadNotificationCount: 0,
  unreadMentions: 0,
  unreadMessages: 0,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@emma:acter.global',
    mockOriginServerTs: 1709100000000, // February 27, 2024
    mockMsgContent: MockMsgContent(
      mockBody:
          'Let me know when you\'re free to discuss the design system updates.',
    ),
  ),
);

final mockChatItem11 = createMockChatItem(
  roomId: 'mock-room-11',
  displayName: 'Alex Thompson',
  notificationMode: 'all',
  activeMembersIds: ['@alex:acter.global', '@kumarpalsinh:acter.global'],
  isDm: true,
  isBookmarked: false,
  unreadNotificationCount: 0,
  unreadMentions: 0,
  unreadMessages: 0,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@alex:acter.global',
    mockOriginServerTs: 1709000000000, // February 26, 2024
    mockMsgContent: MockMsgContent(
      mockBody: 'See you at the team meeting tomorrow at 10 AM.',
    ),
  ),
);

final mockChatItem12 = createMockChatItem(
  roomId: 'mock-room-12',
  displayName: 'Marketing Team',
  notificationMode: 'all',
  activeMembersIds: [
    '@christopher:acter.global',
    '@daniel:acter.global',
    '@james:acter.global',
    '@patricia:acter.global',
  ],
  isDm: false,
  isBookmarked: false,
  unreadNotificationCount: 0,
  unreadMentions: 0,
  unreadMessages: 0,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@christopher:acter.global',
    mockOriginServerTs: 1708900000000, // February 25, 2024
    mockMsgContent: MockMsgContent(
      mockBody:
          'The new campaign has been approved. Launch scheduled for next week.',
    ),
  ),
);

final mockChatItem13 = createMockChatItem(
  roomId: 'mock-room-13',
  displayName: 'Lisa Park',
  notificationMode: 'all',
  activeMembersIds: ['@lisa:acter.global', '@kumarpalsinh:acter.global'],
  isDm: true,
  isBookmarked: false,
  unreadNotificationCount: 0,
  unreadMentions: 0,
  unreadMessages: 0,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@lisa:acter.global',
    mockOriginServerTs: 1708800000000, // February 24, 2024
    mockMsgContent: MockMsgContent(
      mockBody: 'Document reviewed and approved. Ready for implementation.',
    ),
  ),
);

final mockChatItem14 = createMockChatItem(
  roomId: 'mock-room-14',
  displayName: 'Product Feedback',
  notificationMode: 'all',
  activeMembersIds: [
    '@daniel:acter.global',
    '@james:acter.global',
    '@patricia:acter.global',
    '@david:acter.global',
  ],
  isDm: false,
  isBookmarked: false,
  unreadNotificationCount: 0,
  unreadMentions: 0,
  unreadMessages: 0,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@daniel:acter.global',
    mockOriginServerTs: 1708700000000, // February 23, 2024
    mockMsgContent: MockMsgContent(
      mockBody:
          'New feature requests from customer feedback have been prioritized.',
    ),
  ),
);

final mockChatItem15 = createMockChatItem(
  roomId: 'mock-room-15',
  displayName: 'David Miller',
  notificationMode: 'all',
  activeMembersIds: ['@david:acter.global', '@kumarpalsinh:acter.global'],
  isDm: true,
  isBookmarked: false,
  unreadNotificationCount: 0,
  unreadMentions: 0,
  unreadMessages: 0,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@david:acter.global',
    mockOriginServerTs: 1708600000000, // February 22, 2024
    mockMsgContent: MockMsgContent(
      mockBody: 'Task completed and merged to main branch.',
    ),
  ),
);
