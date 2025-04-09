import 'package:acter/features/chat_ui_showcase/models/mock_room.dart';
import 'package:acter/features/chat_ui_showcase/models/mock_convo.dart';

final List<String> mockChatList = [
  'mock-room-1',
  'mock-room-2',
  'mock-room-3',
  'mock-room-4',
  'mock-room-5',
  'mock-room-6',
  'mock-room-7',
  'mock-room-8',
  'mock-room-9',
  'mock-room-10',
];

final List<MockRoom> mockRoomList = [
  MockRoom(
    mockRoomId: 'mock-room-1',
    mockDisplayName: 'Mock Room 1',
    mockNotificationMode: 'muted',
    mockActiveMembersIds: [
      '@mock-member-1:acter.global',
      '@mock-member-2:acter.global',
    ],
  ),
  MockRoom(
    mockRoomId: 'mock-room-2',
    mockDisplayName: 'Mock Room 2',
    mockNotificationMode: 'muted',
    mockActiveMembersIds: [
      '@mock-member-1:acter.global',
      '@mock-member-2:acter.global',
      '@mock-member-3:acter.global',
      '@mock-member-4:acter.global',
    ],
  ),
  MockRoom(
    mockRoomId: 'mock-room-3',
    mockDisplayName: 'Mock Room 3',
    mockNotificationMode: 'muted',
    mockActiveMembersIds: [
      '@mock-member-1:acter.global',
      '@mock-member-2:acter.global',
    ],
  ),
  MockRoom(
    mockRoomId: 'mock-room-4',
    mockDisplayName: 'Mock Room 4',
    mockNotificationMode: 'muted',
    mockActiveMembersIds: [
      '@mock-member-1:acter.global',
      '@mock-member-2:acter.global',
      '@mock-member-3:acter.global',
      '@mock-member-4:acter.global',
    ],
  ),
  MockRoom(
    mockRoomId: 'mock-room-5',
    mockDisplayName: 'Mock Room 5',
    mockNotificationMode: 'muted',
    mockActiveMembersIds: [
      '@mock-member-1:acter.global',
      '@mock-member-2:acter.global',
      '@mock-member-3:acter.global',
      '@mock-member-4:acter.global',
    ],
  ),
  MockRoom(
    mockRoomId: 'mock-room-6',
    mockDisplayName: 'Mock Room 6',
    mockNotificationMode: 'muted',
    mockActiveMembersIds: [
      '@mock-member-1:acter.global',
      '@mock-member-2:acter.global',
    ],
  ),
  MockRoom(
    mockRoomId: 'mock-room-6',
    mockDisplayName: 'Mock Room 6',
    mockNotificationMode: 'muted',
    mockActiveMembersIds: [
      '@mock-member-1:acter.global',
      '@mock-member-2:acter.global',
      '@mock-member-3:acter.global',
      '@mock-member-4:acter.global',
    ],
  ),
  MockRoom(
    mockRoomId: 'mock-room-7',
    mockDisplayName: 'Mock Room 7',
    mockNotificationMode: 'muted',
    mockActiveMembersIds: [
      '@mock-member-1:acter.global',
      '@mock-member-2:acter.global',
      '@mock-member-3:acter.global',
      '@mock-member-4:acter.global',
    ],
  ),
  MockRoom(
    mockRoomId: 'mock-room-8',
    mockDisplayName: 'Mock Room 8',
    mockNotificationMode: 'muted',
    mockActiveMembersIds: [
      '@mock-member-1:acter.global',
      '@mock-member-2:acter.global',
      '@mock-member-3:acter.global',
      '@mock-member-4:acter.global',
    ],
  ),
  MockRoom(
    mockRoomId: 'mock-room-9',
    mockDisplayName: 'Mock Room 9',
    mockNotificationMode: 'muted',
    mockActiveMembersIds: [
      '@mock-member-1:acter.global',
      '@mock-member-2:acter.global',
      '@mock-member-3:acter.global',
      '@mock-member-4:acter.global',
    ],
  ),
  MockRoom(
    mockRoomId: 'mock-room-10',
    mockDisplayName: 'Mock Room 10',
    mockNotificationMode: 'muted',
    mockActiveMembersIds: [
      '@mock-member-1:acter.global',
      '@mock-member-2:acter.global',
      '@mock-member-3:acter.global',
      '@mock-member-4:acter.global',
    ],
  ),
];

final List<MockConvo> mockConvoList = [
  MockConvo(
    mockConvoId: 'mock-room-1',
    mockIsDm: true,
    mockIsBookmarked: true,
    mockNumUnreadNotificationCount: 4,
    mockNumUnreadMentions: 2,
    mockNumUnreadMessages: 2,
    mockTimelineItem: MockTimelineItem(
      mockTimelineEventItem: MockTimelineEventItem(
        mockEventId: 'mock-event-1',
        mockSenderId: '@mock-sender-1:acter.global',
        mockOriginServerTs: 1744018801000,
        mockMsgContent: MockMsgContent(mockBody: 'Hello, how are you?'),
      ),
    ),
  ),
  MockConvo(
    mockConvoId: 'mock-room-2',
    mockIsDm: false,
    mockIsBookmarked: true,
    mockNumUnreadNotificationCount: 1,
    mockNumUnreadMentions: 1,
    mockNumUnreadMessages: 1,
    mockTimelineItem: MockTimelineItem(
      mockTimelineEventItem: MockTimelineEventItem(
        mockEventId: 'mock-event-2',
        mockSenderId: '@mock-sender-2:acter.global',
        mockOriginServerTs: 1744018801000,
        mockMsgContent: MockMsgContent(mockBody: 'Hey, whats up?'),
      ),
    ),
  ),
  MockConvo(
    mockConvoId: 'mock-room-3',
    mockIsDm: true,
    mockIsBookmarked: true,
    mockTimelineItem: MockTimelineItem(
      mockTimelineEventItem: MockTimelineEventItem(
        mockEventId: 'mock-event-3',
        mockSenderId: '@mock-sender-3:acter.global',
        mockOriginServerTs: 1744018801000,
        mockMsgContent: MockMsgContent(mockBody: 'Hey, whats up?'),
      ),
    ),
  ),
  MockConvo(
    mockConvoId: 'mock-room-4',
    mockIsDm: false,
    mockIsBookmarked: false,
    mockTimelineItem: MockTimelineItem(
      mockTimelineEventItem: MockTimelineEventItem(
        mockEventId: 'mock-event-4',
        mockSenderId: '@mock-sender-4:acter.global',
        mockOriginServerTs: 1744018801000,
        mockMsgContent: MockMsgContent(mockBody: 'Hey, whats up?'),
      ),
    ),
  ),
  MockConvo(
    mockConvoId: 'mock-room-5',
    mockIsDm: false,
    mockIsBookmarked: true,
    mockNumUnreadNotificationCount: 3,
    mockNumUnreadMentions: 3,
    mockNumUnreadMessages: 3,
    mockTimelineItem: MockTimelineItem(
      mockTimelineEventItem: MockTimelineEventItem(
        mockEventId: 'mock-event-5',
        mockSenderId: '@mock-sender-5:acter.global',
        mockOriginServerTs: 1744018801000,
        mockMsgContent: MockMsgContent(mockBody: 'Hey, whats up?'),
      ),
    ),
  ),
  MockConvo(
    mockConvoId: 'mock-room-6',
    mockIsDm: true,
    mockIsBookmarked: false,
    mockTimelineItem: MockTimelineItem(
      mockTimelineEventItem: MockTimelineEventItem(
        mockEventId: 'mock-event-6',
        mockSenderId: '@mock-sender-6:acter.global',
        mockOriginServerTs: 1744018801000,
        mockMsgContent: MockMsgContent(mockBody: 'Hey, whats up?'),
      ),
    ),
  ),
  MockConvo(
    mockConvoId: 'mock-room-7',
    mockIsDm: false,
    mockIsBookmarked: false,
    mockTimelineItem: MockTimelineItem(
      mockTimelineEventItem: MockTimelineEventItem(
        mockEventId: 'mock-event-7',
        mockSenderId: '@mock-sender-7:acter.global',
        mockOriginServerTs: 1744018801000,
        mockMsgContent: MockMsgContent(mockBody: 'Hey, whats up?'),
      ),
    ),
  ),
  MockConvo(
    mockConvoId: 'mock-room-8',
    mockIsDm: false,
    mockIsBookmarked: false,
    mockTimelineItem: MockTimelineItem(
      mockTimelineEventItem: MockTimelineEventItem(
        mockEventId: 'mock-event-8',
        mockSenderId: '@mock-sender-8:acter.global',
        mockOriginServerTs: 1744018801000,
        mockMsgContent: MockMsgContent(mockBody: 'Hey, whats up?'),
      ),
    ),
  ),
  MockConvo(
    mockConvoId: 'mock-room-9',
    mockIsDm: false,
    mockIsBookmarked: false,
    mockTimelineItem: MockTimelineItem(
      mockTimelineEventItem: MockTimelineEventItem(
        mockEventId: 'mock-event-9',
        mockSenderId: '@mock-sender-9:acter.global',
        mockOriginServerTs: 1744018801000,
        mockMsgContent: MockMsgContent(mockBody: 'Hey, whats up?'),
      ),
    ),
  ),
  MockConvo(
    mockConvoId: 'mock-room-10',
    mockIsDm: false,
    mockIsBookmarked: false,
    mockTimelineItem: MockTimelineItem(
      mockTimelineEventItem: MockTimelineEventItem(
        mockEventId: 'mock-event-10',
        mockSenderId: '@mock-sender-10:acter.global',
        mockOriginServerTs: 1744018801000,
        mockMsgContent: MockMsgContent(mockBody: 'Hey, whats up?'),
      ),
    ),
  ),
];
