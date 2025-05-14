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
      mockEventId: 'mock-event-id-1',
      mockSenderId: '@emily:acter.global',
      mockOriginServerTs: 1744182966000, // April 9, 2025 10:16:06
      mockMsgContent: MockMsgContent(
        mockBody: 'Hey, how\'s the new feature coming along?',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-2',
      mockSenderId: '@acter1:m-1.acter.global',
      mockOriginServerTs: 1744183026000, // April 9, 2025 10:17:06
      mockMsgContent: MockMsgContent(
        mockBody: 'Making good progress! Just finished the core functionality.',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-3',
      mockSenderId: '@emily:acter.global',
      mockOriginServerTs: 1744183086000, // April 9, 2025 10:18:06
      mockMsgContent: MockMsgContent(
        mockBody:
            'That\'s great! Did you get a chance to test the performance impact?',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-4',
      mockSenderId: '@acter1:m-1.acter.global',
      mockOriginServerTs: 1744183146000, // April 9, 2025 10:19:06
      mockMsgContent: MockMsgContent(
        mockBody:
            'Yes, initial tests show about 15% improvement in response times.',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-5',
      mockSenderId: '@acter1:m-1.acter.global',
      mockOriginServerTs: 1744183156000, // April 9, 2025 10:19:16
      mockMsgContent: MockMsgContent(
        mockBody:
            'I also found a way to optimize the database queries further.',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-6',
      mockSenderId: '@acter1:m-1.acter.global',
      mockOriginServerTs: 1744183166000, // April 9, 2025 10:19:26
      mockMsgContent: MockMsgContent(
        mockBody: 'That should give us another 5-10% boost.',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-7',
      mockSenderId: '@acter1:m-1.acter.global',
      mockOriginServerTs: 1744183176000, // April 9, 2025 10:19:36
      mockEventType: 'ProfileChange',
      mockProfileContent: MockProfileContent(
        mockUserId: '@acter1:m-1.acter.global',
        mockDisplayNameChange: 'Changed',
        mockDisplayNameOldVal: 'David Miller',
        mockDisplayNameNewVal: 'David M.',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-8',
      mockSenderId: '@acter1:m-1.acter.global',
      mockOriginServerTs: 1744183177000, // April 9, 2025 10:19:37
      mockEventType: 'ProfileChange',
      mockProfileContent: MockProfileContent(
        mockUserId: '@acter1:m-1.acter.global',
        mockAvatarUrlChange: 'Changed',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-9',
      mockSenderId: '@emily:acter.global',
      mockOriginServerTs: 1744183178000, // April 9, 2025 10:19:38
      mockEventType: 'ProfileChange',
      mockProfileContent: MockProfileContent(
        mockUserId: '@emily:acter.global',
        mockDisplayNameChange: 'Changed',
        mockDisplayNameOldVal: 'Emily Davis',
        mockDisplayNameNewVal: 'Emily D.',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-10',
      mockSenderId: '@emily:acter.global',
      mockOriginServerTs: 1744183179000, // April 9, 2025 10:19:39
      mockEventType: 'ProfileChange',
      mockProfileContent: MockProfileContent(
        mockUserId: '@emily:acter.global',
        mockAvatarUrlChange: 'Changed',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-11',
      mockSenderId: '@acter1:m-1.acter.global',
      mockOriginServerTs: 1744183180000, // April 9, 2025 10:19:40
      mockEventType: 'ProfileChange',
      mockProfileContent: MockProfileContent(
        mockUserId: '@acter1:m-1.acter.global',
        mockDisplayNameChange: 'Changed',
        mockDisplayNameOldVal: 'David M.',
        mockDisplayNameNewVal: 'David Miller',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-12',
      mockSenderId: '@emily:acter.global',
      mockOriginServerTs: 1744183206000, // April 9, 2025 10:20:06
      mockMsgContent: MockMsgContent(
        mockBody: 'Awesome! Let\'s schedule a demo for the team tomorrow.',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-13',
      mockSenderId: '@emily:acter.global',
      mockOriginServerTs: 1744183216000, // April 9, 2025 10:20:16
      mockMsgContent: MockMsgContent(
        mockBody: 'I\'ll send out the calendar invite.',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-14',
      mockSenderId: '@acter1:m-1.acter.global',
      mockOriginServerTs: 1744183266000, // April 9, 2025 10:21:06
      mockMsgContent: MockMsgContent(
        mockBody: 'Sounds good. I\'ll prepare the presentation deck.',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-15',
      mockSenderId: '@acter1:m-1.acter.global',
      mockOriginServerTs: 1744183276000, // April 9, 2025 10:21:16
      mockMsgContent: MockMsgContent(
        mockBody:
            'I\'ll include a detailed breakdown of the performance improvements, including:\n\n• The database query optimizations we implemented\n• The caching strategy we\'re using for frequently accessed data\n• The new indexing approach that reduced query times by 40%\n• The load testing results under different scenarios\n• A comparison with the previous implementation\n\nThis should give the team a good understanding of the technical improvements.',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-16',
      mockSenderId: '@acter1:m-1.acter.global',
      mockOriginServerTs: 1744183286000, // April 9, 2025 10:21:26
      mockEventType: 'ProfileChange',
      mockProfileContent: MockProfileContent(
        mockUserId: '@acter1:m-1.acter.global',
        mockAvatarUrlChange: 'Changed',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-17',
      mockSenderId: '@emily:acter.global',
      mockOriginServerTs: 1744183326000, // April 9, 2025 10:22:06
      mockMsgContent: MockMsgContent(
        mockBody: 'Perfect! Let me know if you need any help with the demo.',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-18',
      mockSenderId: '@emily:acter.global',
      mockOriginServerTs: 1744183336000, // April 9, 2025 10:22:16
      mockMsgContent: MockMsgContent(
        mockBody: 'I can review the slides before the meeting.',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-19',
      mockSenderId: '@emily:acter.global',
      mockOriginServerTs: 1744183346000, // April 9, 2025 10:22:26
      mockMsgContent: MockMsgContent(
        mockBody:
            'Also, I was thinking about the next steps after this feature launch. Here\'s what I have in mind:\n\n1. Monitor the performance metrics for at least a week to ensure stability\n2. Gather user feedback through the new analytics dashboard\n3. Plan a follow-up sprint to address any issues that come up\n4. Consider expanding the feature to other parts of the application\n5. Document the implementation details for the team wiki\n\nWhat do you think about this approach?',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-20',
      mockSenderId: '@emily:acter.global',
      mockOriginServerTs: 1744183356000, // April 9, 2025 10:22:36
      mockEventType: 'ProfileChange',
      mockProfileContent: MockProfileContent(
        mockUserId: '@emily:acter.global',
        mockDisplayNameChange: 'Changed',
        mockDisplayNameOldVal: 'Emily D.',
        mockDisplayNameNewVal: 'Emily Davis',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-21',
      mockSenderId: '@emily:acter.global',
      mockOriginServerTs: 1744183357000, // April 9, 2025 10:22:37
      mockEventType: 'ProfileChange',
      mockProfileContent: MockProfileContent(
        mockUserId: '@emily:acter.global',
        mockAvatarUrlChange: 'Changed',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-22',
      mockSenderId: '@acter1:m-1.acter.global',
      mockOriginServerTs: 1744183386000, // April 9, 2025 10:23:06
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
    '@acter1:m-1.acter.global',
  ],
  unreadNotificationCount: 2,
  unreadMessages: 2,
  typingUsers: [
    MockUser(mockDisplayName: 'Emily', mockUserId: '@emily:acter.global'),
  ],
  timelineEventItems: [
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-23',
      mockSenderId: '@michael:acter.global',
      mockOriginServerTs: 1744096555000, // April 8, 2025 15:35:55
      mockEventType: 'm.room.encrypted',
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-24',
      mockSenderId: '@acter1:m-1.acter.global',
      mockOriginServerTs: 1744096555000, // April 8, 2025 15:35:55
      mockEventType: 'm.room.encrypted',
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-25',
      mockSenderId: '@acter1:m-1.acter.global',
      mockOriginServerTs: 1744096555000, // April 8, 2025 15:35:55
      mockEventType: 'm.room.encrypted',
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-26',
      mockSenderId: '@sarah:acter.global',
      mockOriginServerTs: 1744096556000, // April 8, 2025 15:35:56
      mockEventType: 'm.room.redaction',
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-27',
      mockSenderId: '@sarah:acter.global',
      mockOriginServerTs: 1744096556000, // April 8, 2025 15:35:56
      mockEventType: 'm.room.redaction',
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-28',
      mockSenderId: '@sarah:acter.global',
      mockOriginServerTs: 1744096556000, // April 8, 2025 15:35:56
      mockEventType: 'm.room.redaction',
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-29',
      mockSenderId: '@sarah:acter.global',
      mockOriginServerTs: 1744096566000, // April 8, 2025 15:36:06
      mockMsgContent: MockMsgContent(
        mockBody: 'Deployment tomorrow at 2 PM. Review checklist.',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-30',
      mockSenderId: '@michael:acter.global',
      mockOriginServerTs: 1744096626000, // April 8, 2025 15:37:06
      mockMsgContent: MockMsgContent(
        mockBody: 'I\'ve reviewed the checklist. Everything looks good.',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-31',
      mockSenderId: '@michael:acter.global',
      mockOriginServerTs: 1744096636000, // April 8, 2025 15:37:16
      mockMsgContent: MockMsgContent(
        mockBody: 'Just need to confirm the database backup is scheduled.',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-32',
      mockSenderId: '@michael:acter.global',
      mockOriginServerTs: 1744096686000, // April 8, 2025 15:38:06
      mockMsgContent: MockMsgContent(
        mockBody: 'Database backup is scheduled for 1 PM.',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-33',
      mockSenderId: '@lisa:acter.global',
      mockOriginServerTs: 1744096696000, // April 8, 2025 15:38:16
      mockEventType: 'ProfileChange',
      mockProfileContent: MockProfileContent(
        mockUserId: '@lisa:acter.global',
        mockDisplayNameChange: 'Changed',
        mockDisplayNameOldVal: 'Lisa Park',
        mockDisplayNameNewVal: 'Lisa P.',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-34',
      mockSenderId: '@alex:acter.global',
      mockOriginServerTs: 1744096746000, // April 8, 2025 15:39:06
      mockMsgContent: MockMsgContent(
        mockBody: 'I\'ll be handling the frontend deployment.',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-35',
      mockSenderId: '@alex:acter.global',
      mockOriginServerTs: 1744096756000, // April 8, 2025 15:39:16
      mockEventType: 'ProfileChange',
      mockProfileContent: MockProfileContent(
        mockUserId: '@alex:acter.global',
        mockAvatarUrlChange: 'Changed',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-36',
      mockSenderId: '@acter1:m-1.acter.global',
      mockOriginServerTs: 1744096806000, // April 8, 2025 15:40:06
      mockMsgContent: MockMsgContent(
        mockBody:
            'Backend deployment is ready. I\'ve tested the staging environment.',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-37',
      mockSenderId: '@acter1:m-1.acter.global',
      mockOriginServerTs: 1744096816000, // April 8, 2025 15:40:16
      mockMsgContent: MockMsgContent(
        mockBody: 'All API endpoints are responding correctly.',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-38',
      mockSenderId: '@acter1:m-1.acter.global',
      mockOriginServerTs: 1744096826000, // April 8, 2025 15:40:26
      mockEventType: 'ProfileChange',
      mockProfileContent: MockProfileContent(
        mockUserId: '@acter1:m-1.acter.global',
        mockDisplayNameChange: 'Changed',
        mockDisplayNameOldVal: 'David Miller',
        mockDisplayNameNewVal: 'David M.',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-39',
      mockSenderId: '@sarah:acter.global',
      mockOriginServerTs: 1744096866000, // April 8, 2025 15:41:06
      mockMsgContent: MockMsgContent(
        mockBody:
            'Great! Let\'s go through the deployment steps:\n\n1. Database backup (1 PM)\n2. Frontend deployment (1:30 PM)\n3. Backend deployment (1:45 PM)\n4. Smoke testing (2 PM)\n5. Monitoring for 30 minutes\n\nEveryone clear on their roles?',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-40',
      mockSenderId: '@michael:acter.global',
      mockOriginServerTs: 1744096926000, // April 8, 2025 15:42:06
      mockMsgContent: MockMsgContent(
        mockBody: 'Yes, I\'ll be monitoring the logs during deployment.',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-41',
      mockSenderId: '@michael:acter.global',
      mockOriginServerTs: 1744096936000, // April 8, 2025 15:42:16
      mockEventType: 'ProfileChange',
      mockProfileContent: MockProfileContent(
        mockUserId: '@michael:acter.global',
        mockDisplayNameChange: 'Changed',
        mockDisplayNameOldVal: 'Michael Chen',
        mockDisplayNameNewVal: 'Michael C.',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-42',
      mockSenderId: '@lisa:acter.global',
      mockOriginServerTs: 1744096986000, // April 8, 2025 15:43:06
      mockMsgContent: MockMsgContent(
        mockBody: 'I\'ll handle the smoke testing.',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-43',
      mockSenderId: '@lisa:acter.global',
      mockOriginServerTs: 1744096996000, // April 8, 2025 15:43:16
      mockEventType: 'ProfileChange',
      mockProfileContent: MockProfileContent(
        mockUserId: '@lisa:acter.global',
        mockDisplayNameChange: 'Changed',
        mockDisplayNameOldVal: 'Lisa P.',
        mockDisplayNameNewVal: 'Lisa Park',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-44',
      mockSenderId: '@alex:acter.global',
      mockOriginServerTs: 1744097046000, // April 8, 2025 15:44:06
      mockMsgContent: MockMsgContent(
        mockBody:
            'Frontend is ready to go. I\'ve prepared the deployment script.',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-45',
      mockSenderId: '@alex:acter.global',
      mockOriginServerTs: 1744097056000, // April 8, 2025 15:44:16
      mockEventType: 'ProfileChange',
      mockProfileContent: MockProfileContent(
        mockUserId: '@alex:acter.global',
        mockAvatarUrlChange: 'Changed',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-46',
      mockSenderId: '@sarah:acter.global',
      mockOriginServerTs: 1744097106000, // April 8, 2025 15:45:06
      mockMsgContent: MockMsgContent(
        mockBody:
            'Perfect! Let\'s meet in the deployment channel 10 minutes before start time.',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-47',
      mockSenderId: '@sarah:acter.global',
      mockOriginServerTs: 1744097116000, // April 8, 2025 15:45:16
      mockEventType: 'ProfileChange',
      mockProfileContent: MockProfileContent(
        mockUserId: '@sarah:acter.global',
        mockDisplayNameChange: 'Changed',
        mockDisplayNameOldVal: 'Sarah Wilson',
        mockDisplayNameNewVal: 'Sarah W.',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-48',
      mockSenderId: '@acter1:m-1.acter.global',
      mockOriginServerTs: 1744097166000, // April 8, 2025 15:46:06
      mockMsgContent: MockMsgContent(
        mockBody: 'Will do! See you all tomorrow.',
      ),
    ),

    // --- Reply-to-message example ---
    MockTimelineEventItem(
      mockEventId: 'mock-reply-base',
      mockSenderId: '@acter1:m-1.acter.global',
      mockOriginServerTs: 1744098000000, // April 8, 2025 16:00:00
      mockMsgContent: MockMsgContent(
        mockBody:
            'I would like to see some UI example of how media messages are renders in ...',
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-reply-1',
      mockSenderId: '@sarah:acter.global',
      mockOriginServerTs: 1744098060000, // April 8, 2025 16:01:00
      mockMsgContent: MockMsgContent(
        mockBody:
            'I have have share file as requested.\n\nYes, thanks a lot for it. :)',
      ),
      mockInReplyToId: 'mock-reply-base',
      mockIsReplyToEvent: MockTimelineEventItem(
        mockEventId: 'mock-reply-base',
        mockSenderId: '@acter1:m-1.acter.global',
        mockOriginServerTs: 1744098000000, // April 8, 2025 16:00:00
        mockMsgContent: MockMsgContent(
          mockBody:
              'I would like to see some UI example of how media messages are renders in ...',
        ),
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-reply-2',
      mockSenderId: '@acter1:m-1.acter.global',
      mockOriginServerTs: 1744098120000, // April 8, 2025 16:02:00
      mockMsgContent: MockMsgContent(
        mockBody: 'Thanks Sarah! I will check the file and get back to you.',
      ),
      mockInReplyToId: 'mock-reply-1',
      mockIsReplyToEvent: MockTimelineEventItem(
        mockEventId: 'mock-reply-1',
        mockSenderId: '@sarah:acter.global',
        mockOriginServerTs: 1744098060000,
        mockMsgContent: MockMsgContent(
          mockBody:
              'I have have share file as requested.\n\nYes, thanks a lot for it. :)',
        ),
        mockInReplyToId: 'mock-reply-base',
        mockIsReplyToEvent: MockTimelineEventItem(
          mockEventId: 'mock-reply-base',
          mockSenderId: '@acter1:m-1.acter.global',
          mockOriginServerTs: 1744098000000,
          mockMsgContent: MockMsgContent(
            mockBody:
                'I would like to see some UI example of how media messages are renders in ...',
          ),
        ),
      ),
    ),
    MockTimelineEventItem(
      mockEventId: 'mock-reply-3',
      mockSenderId: '@acter1:m-1.acter.global',
      mockOriginServerTs: 1744098180000, // April 8, 2025 16:03:00
      mockMsgContent: MockMsgContent(
        mockBody: 'Let me know if you need any more examples or help!',
      ),
      mockInReplyToId: 'mock-reply-1',
      mockIsReplyToEvent: MockTimelineEventItem(
        mockEventId: 'mock-reply-1',
        mockSenderId: '@sarah:acter.global',
        mockOriginServerTs: 1744098060000,
        mockMsgContent: MockMsgContent(
          mockBody:
              'I have have share file as requested.\n\nYes, thanks a lot for it. :)',
        ),
        mockInReplyToId: 'mock-reply-base',
        mockIsReplyToEvent: MockTimelineEventItem(
          mockEventId: 'mock-reply-base',
          mockSenderId: '@acter1:m-1.acter.global',
          mockOriginServerTs: 1744098000000,
          mockMsgContent: MockMsgContent(
            mockBody:
                'I would like to see some UI example of how media messages are renders in ...',
          ),
        ),
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
      mockEventId: 'mock-event-id-31',
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
      mockEventId: 'mock-event-id-32',
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
      mockEventId: 'mock-event-id-33',
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
  typingUsers: [
    MockUser(mockDisplayName: 'Sarah', mockUserId: '@sarah:acter.global'),
  ],
  timelineEventItems: [
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-34',
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
    MockUser(mockDisplayName: 'Jennifer', mockUserId: '@jennifer:acter.global'),
    MockUser(mockDisplayName: 'James', mockUserId: '@james:acter.global'),
    MockUser(mockDisplayName: 'David', mockUserId: '@david:acter.global'),
  ],
  activeMembersIds: [
    '@jennifer:acter.global',
    '@james:acter.global',
    '@patricia:acter.global',
    '@david:acter.global',
  ],
  timelineEventItems: [
    MockTimelineEventItem(
      mockEventId: 'mock-event-id-35',
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
      mockEventId: 'mock-event-id-36',
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
      mockEventId: 'mock-event-id-37',
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
      mockEventId: 'mock-event-id-38',
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
      mockEventId: 'mock-event-id-39',
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
      mockEventId: 'mock-event-id-40',
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
      mockEventId: 'mock-event-id-41',
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
      mockEventId: 'mock-event-id-42',
      mockSenderId: '@daniel:acter.global',
      mockOriginServerTs: 1743059766000, // March 27, 2025
      mockMsgContent: MockMsgContent(mockBody: 'Feature requests prioritized.'),
    ),
  ],
);
