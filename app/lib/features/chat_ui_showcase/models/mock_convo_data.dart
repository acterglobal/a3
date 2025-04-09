import 'package:acter/features/chat_ui_showcase/models/mock_convo.dart';
import 'package:acter/features/chat_ui_showcase/models/mock_room.dart';
import 'package:acter/features/chat_ui_showcase/models/mock_user.dart';

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
    mockOriginServerTs: 1744182966000, // April 9, 2025
    mockMsgContent: MockMsgContent(mockBody: 'Hey, whats the update?'),
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

final mockChatItem3 = createMockChatItem(
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

final mockChatItem4 = createMockChatItem(
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

final mockChatItem5 = createMockChatItem(
  roomId: 'mock-room-5',
  displayName: 'Michael, Kumarpalsinh & Ben',
  activeMembersIds: [
    '@michael:acter.global',
    '@kumarpalsinh:acter.global',
    '@ben:acter.global',
  ],
  isDm: true,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@michael:acter.global',
    mockOriginServerTs: 1743837366000, // April 5, 2025
    mockMsgContent: MockMsgContent(
      mockBody: 'Can we schedule a quick sync about the API changes?',
    ),
  ),
);

final mockChatItem6 = createMockChatItem(
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

final mockChatItem7 = createMockChatItem(
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

final mockChatItem8 = createMockChatItem(
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

final mockChatItem9 = createMockChatItem(
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

final mockChatItem10 = createMockChatItem(
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

final mockChatItem11 = createMockChatItem(
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

final mockChatItem12 = createMockChatItem(
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

final mockChatItem13 = createMockChatItem(
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

final mockChatItem14 = createMockChatItem(
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

final mockChatItem15 = createMockChatItem(
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
