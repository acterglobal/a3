import 'package:acter/features/chat_ui_showcase/mocks/convo/timeline/mock_timeline_event_item.dart';
import 'package:acter/features/chat_ui_showcase/mocks/general/mock_msg_content.dart';
import 'package:acter/features/chat_ui_showcase/mocks/showcase/convo_showcase_data.dart';

final davidDmRoom15 = createMockChatItem(
  roomId: 'mock-room-15',
  displayName: 'David Miller',
  activeMembersIds: ['@david:acter.global', '@kumarpalsinh:acter.global'],
  isDm: true,
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@david:acter.global',
      mockOriginServerTs: 1742973366000, // March 26, 2025
      mockMsgContent: MockMsgContent(
        mockBody: 'Task completed and merged to main branch.',
      ),
    ),
  ],
);

final imageMessageDmRoom16 = createMockChatItem(
  roomId: 'mock-room-16',
  displayName: 'Meeko',
  activeMembersIds: ['@meeko:acter.global', '@kumarpalsinh:acter.global'],
  isDm: true,
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@meeko:acter.global',
      mockOriginServerTs: 1743318966000, // March 30, 2025
      mockMsgType: 'm.image',
      mockEventType: 'm.room.message',
      mockMsgContent: MockMsgContent(
        mockBody: 'Image message about the API changes',
      ),
    ),
  ],
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
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@david:acter.global',
      mockOriginServerTs: 1743318966000, // March 30, 2025
      mockMsgType: 'm.video',
      mockEventType: 'm.room.message',
      mockMsgContent: MockMsgContent(
        mockBody: 'Video message about the API changes',
      ),
    ),
  ],
);

final audioMessageDmRoom18 = createMockChatItem(
  roomId: 'mock-room-18',
  displayName: 'Max Leon',
  activeMembersIds: ['@maxleon:acter.global', '@kumarpalsinh:acter.global'],
  isDm: true,
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@maxleon:acter.global',
      mockOriginServerTs: 1743318966000, // March 30, 2025
      mockMsgType: 'm.audio',
      mockEventType: 'm.room.message',
      mockMsgContent: MockMsgContent(
        mockBody: 'Voice message about the API changes',
      ),
    ),
  ],
);

final fileMessageDmRoom19 = createMockChatItem(
  roomId: 'mock-room-19',
  displayName: 'Jennifer Lee',
  activeMembersIds: ['@jennifer:acter.global', '@kumarpalsinh:acter.global'],
  isDm: true,
  isBookmarked: true,
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@jennifer:acter.global',
      mockOriginServerTs: 1743232566000, // March 29, 2025
      mockMsgType: 'm.file',
      mockEventType: 'm.room.message',
      mockMsgContent: MockMsgContent(mockBody: 'Project proposal document'),
    ),
  ],
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
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@michael:acter.global',
      mockOriginServerTs: 1743146166000, // March 28, 2025
      mockMsgType: 'm.location',
      mockEventType: 'm.room.message',
      mockMsgContent: MockMsgContent(mockBody: 'Meeting location'),
    ),
  ],
);

final redactionEventRoom21 = createMockChatItem(
  roomId: 'mock-room-21',
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
      mockEventType: 'm.room.redaction',
      mockMsgContent: MockMsgContent(mockBody: 'Message was redacted'),
    ),
  ],
);
