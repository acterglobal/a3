import 'package:acter/features/chat_ui_showcase/mocks/convo/mock_profile_content.dart';
import 'package:acter/features/chat_ui_showcase/mocks/convo/timeline/mock_timeline_event_item.dart';
import 'package:acter/features/chat_ui_showcase/mocks/general/mock_msg_content.dart';
import 'package:acter/features/chat_ui_showcase/mocks/showcase/convo_showcase_data.dart';
import 'package:acter/features/chat_ui_showcase/mocks/user/mock_user.dart';

final emilyDmMutedBookmarkedRoom1 = createMockChatItem(
  roomId: 'mock-room-1',
  displayName: 'Emily Davis',
  notificationMode: 'muted',
  activeMembersIds: ['@emily:acter.global', '@acter1:m-1.acter.global'],
  isDm: true,
  isBookmarked: true,
  unreadNotificationCount: 4,
  unreadMentions: 2,
  unreadMessages: 2,
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@emily:acter.global',
      mockOriginServerTs: 1744182966000, // April 9, 2025
      mockMsgContent: MockMsgContent(
        mockBody: 'Hey, how\'s the new feature coming along?',
      ),
    ),
    MockTimelineEventItem(
      mockSenderId: '@acter1:m-1.acter.global',
      mockOriginServerTs: 1744183026000, // 1 minute later
      mockMsgContent: MockMsgContent(
        mockBody: 'Making good progress! Just finished the core functionality.',
      ),
    ),
    MockTimelineEventItem(
      mockSenderId: '@emily:acter.global',
      mockOriginServerTs: 1744183086000, // 2 minutes later
      mockMsgContent: MockMsgContent(
        mockBody:
            'That\'s great! Did you get a chance to test the performance impact?',
      ),
    ),
    MockTimelineEventItem(
      mockSenderId: '@acter1:m-1.acter.global',
      mockOriginServerTs: 1744183146000, // 3 minutes later
      mockMsgContent: MockMsgContent(
        mockBody:
            'Yes, initial tests show about 15% improvement in response times.',
      ),
    ),
    MockTimelineEventItem(
      mockSenderId: '@acter1:m-1.acter.global',
      mockOriginServerTs: 1744183156000, // 10 seconds later
      mockMsgContent: MockMsgContent(
        mockBody:
            'I also found a way to optimize the database queries further.',
      ),
    ),
    MockTimelineEventItem(
      mockSenderId: '@acter1:m-1.acter.global',
      mockOriginServerTs: 1744183166000, // 20 seconds later
      mockMsgContent: MockMsgContent(
        mockBody: 'That should give us another 5-10% boost.',
      ),
    ),
    MockTimelineEventItem(
      mockSenderId: '@acter1:m-1.acter.global',
      mockOriginServerTs: 1744183176000, // 30 seconds later
      mockEventType: 'ProfileChange',
      mockProfileContent: MockProfileContent(
        mockUserId: '@acter1:m-1.acter.global',
        mockDisplayNameChange: 'Changed',
        mockDisplayNameOldVal: 'David Miller',
        mockDisplayNameNewVal: 'David M.',
      ),
    ),
    MockTimelineEventItem(
      mockSenderId: '@acter1:m-1.acter.global',
      mockOriginServerTs: 1744183177000, // 1 second later
      mockEventType: 'ProfileChange',
      mockProfileContent: MockProfileContent(
        mockUserId: '@acter1:m-1.acter.global',
        mockAvatarUrlChange: 'Changed',
      ),
    ),
    MockTimelineEventItem(
      mockSenderId: '@emily:acter.global',
      mockOriginServerTs: 1744183178000, // 2 seconds later
      mockEventType: 'ProfileChange',
      mockProfileContent: MockProfileContent(
        mockUserId: '@emily:acter.global',
        mockDisplayNameChange: 'Changed',
        mockDisplayNameOldVal: 'Emily Davis',
        mockDisplayNameNewVal: 'Emily D.',
      ),
    ),
    MockTimelineEventItem(
      mockSenderId: '@emily:acter.global',
      mockOriginServerTs: 1744183179000, // 3 seconds later
      mockEventType: 'ProfileChange',
      mockProfileContent: MockProfileContent(
        mockUserId: '@emily:acter.global',
        mockAvatarUrlChange: 'Changed',
      ),
    ),
    MockTimelineEventItem(
      mockSenderId: '@acter1:m-1.acter.global',
      mockOriginServerTs: 1744183180000, // 4 seconds later
      mockEventType: 'ProfileChange',
      mockProfileContent: MockProfileContent(
        mockUserId: '@acter1:m-1.acter.global',
        mockDisplayNameChange: 'Changed',
        mockDisplayNameOldVal: 'David M.',
        mockDisplayNameNewVal: 'David Miller',
      ),
    ),
    MockTimelineEventItem(
      mockSenderId: '@emily:acter.global',
      mockOriginServerTs: 1744183206000, // 4 minutes later
      mockMsgContent: MockMsgContent(
        mockBody: 'Awesome! Let\'s schedule a demo for the team tomorrow.',
      ),
    ),
    MockTimelineEventItem(
      mockSenderId: '@emily:acter.global',
      mockOriginServerTs: 1744183216000, // 10 seconds later
      mockMsgContent: MockMsgContent(
        mockBody: 'I\'ll send out the calendar invite.',
      ),
    ),
    MockTimelineEventItem(
      mockSenderId: '@acter1:m-1.acter.global',
      mockOriginServerTs: 1744183266000, // 5 minutes later
      mockMsgContent: MockMsgContent(
        mockBody: 'Sounds good. I\'ll prepare the presentation deck.',
      ),
    ),
    MockTimelineEventItem(
      mockSenderId: '@acter1:m-1.acter.global',
      mockOriginServerTs: 1744183276000, // 10 seconds later
      mockMsgContent: MockMsgContent(
        mockBody:
            'I\'ll include a detailed breakdown of the performance improvements, including:\n\n• The database query optimizations we implemented\n• The caching strategy we\'re using for frequently accessed data\n• The new indexing approach that reduced query times by 40%\n• The load testing results under different scenarios\n• A comparison with the previous implementation\n\nThis should give the team a good understanding of the technical improvements.',
      ),
    ),
    MockTimelineEventItem(
      mockSenderId: '@acter1:m-1.acter.global',
      mockOriginServerTs: 1744183286000, // 20 seconds later
      mockEventType: 'ProfileChange',
      mockProfileContent: MockProfileContent(
        mockUserId: '@acter1:m-1.acter.global',
        mockAvatarUrlChange: 'Changed',
      ),
    ),
    MockTimelineEventItem(
      mockSenderId: '@emily:acter.global',
      mockOriginServerTs: 1744183326000, // 6 minutes later
      mockMsgContent: MockMsgContent(
        mockBody: 'Perfect! Let me know if you need any help with the demo.',
      ),
    ),
    MockTimelineEventItem(
      mockSenderId: '@emily:acter.global',
      mockOriginServerTs: 1744183336000, // 10 seconds later
      mockMsgContent: MockMsgContent(
        mockBody: 'I can review the slides before the meeting.',
      ),
    ),
    MockTimelineEventItem(
      mockSenderId: '@emily:acter.global',
      mockOriginServerTs: 1744183346000, // 20 seconds later
      mockMsgContent: MockMsgContent(
        mockBody:
            'Also, I was thinking about the next steps after this feature launch. Here\'s what I have in mind:\n\n1. Monitor the performance metrics for at least a week to ensure stability\n2. Gather user feedback through the new analytics dashboard\n3. Plan a follow-up sprint to address any issues that come up\n4. Consider expanding the feature to other parts of the application\n5. Document the implementation details for the team wiki\n\nWhat do you think about this approach?',
      ),
    ),
    MockTimelineEventItem(
      mockSenderId: '@emily:acter.global',
      mockOriginServerTs: 1744183356000, // 30 seconds later
      mockEventType: 'ProfileChange',
      mockProfileContent: MockProfileContent(
        mockUserId: '@emily:acter.global',
        mockDisplayNameChange: 'Changed',
        mockDisplayNameOldVal: 'Emily D.',
        mockDisplayNameNewVal: 'Emily Davis',
      ),
    ),
    MockTimelineEventItem(
      mockSenderId: '@emily:acter.global',
      mockOriginServerTs: 1744183357000, // 31 seconds later
      mockEventType: 'ProfileChange',
      mockProfileContent: MockProfileContent(
        mockUserId: '@emily:acter.global',
        mockAvatarUrlChange: 'Changed',
      ),
    ),
    MockTimelineEventItem(
      mockSenderId: '@acter1:m-1.acter.global',
      mockOriginServerTs: 1744183386000, // 7 minutes later
      mockMsgContent: MockMsgContent(
        mockBody: 'Will do! Thanks for checking in.',
      ),
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
