import 'package:acter/features/chat_ui_showcase/mocks/convo/timeline/mock_timeline_event_item.dart';
import 'package:acter/features/chat_ui_showcase/mocks/general/mock_msg_content.dart';
import 'package:acter/features/chat_ui_showcase/mocks/showcase/convo_showcase_data.dart';
import 'package:acter/features/chat_ui_showcase/mocks/user/mock_user.dart';

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
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@emily:acter.global',
      mockOriginServerTs: 1744182966000, // April 9, 2025
      mockMsgContent: MockMsgContent(mockBody: 'Hey, whats the update?'),
    ),
  ],
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
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@sarah:acter.global',
      mockOriginServerTs: 1744096566000, // April 8, 2025
      mockMsgContent: MockMsgContent(
        mockBody: 'Deployment tomorrow at 2 PM. Review checklist.',
      ),
    ),
  ],
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
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@robert:acter.global',
      mockOriginServerTs: 1744010166000, // April 7, 2025
      mockMsgContent: MockMsgContent(mockBody: 'CI/CD fixed. Tests passing.'),
    ),
  ],
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
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@emma:acter.global',
      mockOriginServerTs: 1743923766000, // April 6, 2025
      mockMsgContent: MockMsgContent(
        mockBody: 'UI components updated. Please review.',
      ),
    ),
  ],
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
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@michael:acter.global',
      mockOriginServerTs: 1743837366000, // April 5, 2025
      mockMsgContent: MockMsgContent(
        mockBody: 'Can we schedule a quick sync about the API changes?',
      ),
    ),
  ],
);

final sarahDmWithTypingRoom6 = createMockChatItem(
  roomId: 'mock-room-6',
  displayName: 'Sarah Wilson',
  activeMembersIds: ['@sarah:acter.global', '@kumarpalsinh:acter.global'],
  isDm: true,
  typingUsers: [MockUser(mockDisplayName: 'Sarah')],
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@sarah:acter.global',
      mockOriginServerTs: 1743750966000, // April 4, 2025
      mockMsgContent: MockMsgContent(
        mockBody:
            'The meeting notes are ready. I\'ve highlighted the action items.',
      ),
    ),
  ],
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
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@jennifer:acter.global',
      mockOriginServerTs: 1743664566000, // April 3, 2025
      mockMsgContent: MockMsgContent(
        mockBody: 'Sprint retro tomorrow at 11 AM.',
      ),
    ),
  ],
);

final lisaDmBookmarkedImageMessageRoom8 = createMockChatItem(
  roomId: 'mock-room-8',
  displayName: 'Lisa Park',
  activeMembersIds: ['@lisa:acter.global', '@kumarpalsinh:acter.global'],
  isDm: true,
  isBookmarked: true,
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@lisa:acter.global',
      mockOriginServerTs: 1743578166000, // April 2, 2025
      mockMsgContent: MockMsgContent(
        mockBody: 'The documentation is updated with the latest API changes.',
      ),
    ),
  ],
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
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@emily:acter.global',
      mockOriginServerTs: 1743491766000, // April 1, 2025
      mockMsgContent: MockMsgContent(
        mockBody: 'New features deployed. Monitor for issues.',
      ),
    ),
  ],
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
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@emma:acter.global',
      mockOriginServerTs: 1743405366000, // March 31, 2025
      mockMsgContent: MockMsgContent(
        mockBody:
            'Let me know when you\'re free to discuss the design system updates.',
      ),
    ),
  ],
);

final alexDmRoom11 = createMockChatItem(
  roomId: 'mock-room-11',
  displayName: 'Alex Thompson',
  activeMembersIds: ['@alex:acter.global', '@kumarpalsinh:acter.global'],
  isDm: true,
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@alex:acter.global',
      mockOriginServerTs: 1743318966000, // March 30, 2025
      mockMsgContent: MockMsgContent(
        mockBody: 'See you at the team meeting tomorrow at 10 AM.',
      ),
    ),
  ],
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
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@christopher:acter.global',
      mockOriginServerTs: 1743232566000, // March 29, 2025
      mockMsgContent: MockMsgContent(
        mockBody: 'Campaign approved. Launch next week.',
      ),
    ),
  ],
);

final lisaDmRoom13 = createMockChatItem(
  roomId: 'mock-room-13',
  displayName: 'Lisa Park',
  activeMembersIds: ['@lisa:acter.global', '@kumarpalsinh:acter.global'],
  isDm: true,
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@lisa:acter.global',
      mockOriginServerTs: 1743146166000, // March 28, 2025
      mockMsgContent: MockMsgContent(
        mockBody: 'Document reviewed and approved. Ready for implementation.',
      ),
    ),
  ],
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
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@daniel:acter.global',
      mockOriginServerTs: 1743059766000, // March 27, 2025
      mockMsgContent: MockMsgContent(mockBody: 'Feature requests prioritized.'),
    ),
  ],
);
