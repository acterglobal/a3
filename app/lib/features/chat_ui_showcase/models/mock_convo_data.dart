import 'package:acter/features/chat_ui_showcase/models/mock_timeline_event_item.dart';
import 'package:acter/features/chat_ui_showcase/models/mock_user.dart';

class MockChatItem {
  final String roomId;
  final bool isDM;
  final String displayName;
  final MockTimelineEventItem lastMessage;
  final List<MockUser>? typingUsers;
  final int unreadCount;
  final bool isMuted;
  final bool isBookmarked;

  MockChatItem({
    required this.roomId,
    required this.isDM,
    required this.displayName,
    required this.lastMessage,
    this.unreadCount = 0,
    this.typingUsers,
    this.isMuted = false,
    this.isBookmarked = false,
  });
}

final mockChatItem1 = MockChatItem(
  roomId: 'room-1',
  isDM: true,
  displayName: 'John Doe',
  lastMessage: MockTimelineEventItem(
    mockEventId: 'event-1',
    mockSenderId: 'John Doe',
    mockOriginServerTs: 1744018801000,
    mockMsgContent: MockMsgContent(mockBody: 'Hello, how are you?'),
  ),
  unreadCount: 1,
  isMuted: true,
  isBookmarked: true,
);

final mockChatItem2 = MockChatItem(
  roomId: 'room-2',
  isDM: false,
  displayName: 'Social Media',
  lastMessage: MockTimelineEventItem(
    mockEventId: 'event-2',
    mockSenderId: 'Sarah Wilson',
    mockOriginServerTs: 1743699332000,
    mockMsgContent: MockMsgContent(mockBody: 'Hello, how are you?'),
  ),
  unreadCount: 2,
  typingUsers: [MockUser(mockUserId: 'Michael Chen')],
  isMuted: true,
);

final mockChatItem3 = MockChatItem(
  roomId: 'room-2',
  isDM: false,
  displayName: 'Acter Tech',
  lastMessage: MockTimelineEventItem(
    mockEventId: 'event-3',
    mockSenderId: 'Emma Davis',
    mockOriginServerTs: 1743700332000,
    mockMsgContent: MockMsgContent(mockBody: 'Hello, how are you?'),
  ),
  unreadCount: 2,
);

final mockChatItem4 = MockChatItem(
  roomId: 'room-4',
  isDM: false,
  displayName: 'Acter Team',
  lastMessage: MockTimelineEventItem(
    mockEventId: 'event-4',
    mockSenderId: 'Alex Thompson',
    mockOriginServerTs: 1743701332000,
    mockMsgContent: MockMsgContent(mockBody: 'Hello, how are you?'),
  ),
  isMuted: true,
  isBookmarked: true,
);

final mockChatItem5 = MockChatItem(
  roomId: 'room-5',
  isDM: true,
  displayName: 'Kumarpalsinh Rana',
  lastMessage: MockTimelineEventItem(
    mockEventId: 'event-5',
    mockSenderId: 'Lisa Park',
    mockOriginServerTs: 1743702332000,
    mockMsgContent: MockMsgContent(mockBody: 'Hello, how are you?'),
  ),
  typingUsers: [MockUser(mockUserId: 'David Miller')],
);

final mockChatItem6 = MockChatItem(
  roomId: 'room-6',
  isDM: true,
  displayName: 'Sarah Wilson',
  lastMessage: MockTimelineEventItem(
    mockEventId: 'event-6',
    mockSenderId: 'Robert Johnson',
    mockOriginServerTs: 1743703332000,
    mockMsgContent: MockMsgContent(mockBody: 'Hello, how are you?'),
  ),
);

final mockChatItem7 = MockChatItem(
  roomId: 'room-7',
  isDM: false,
  displayName: 'Project Alpha',
  lastMessage: MockTimelineEventItem(
    mockEventId: 'event-7',
    mockSenderId: 'Jennifer Lee',
    mockOriginServerTs: 1743704332000,
    mockMsgContent: MockMsgContent(mockBody: 'Meeting notes attached'),
  ),
  typingUsers: [
    MockUser(mockUserId: 'James Wilson'),
    MockUser(mockUserId: 'Patricia Brown'),
  ],
);

final mockChatItem8 = MockChatItem(
  roomId: 'room-8',
  isDM: true,
  displayName: 'Michael Chen',
  lastMessage: MockTimelineEventItem(
    mockEventId: 'event-8',
    mockSenderId: 'Michael Chen',
    mockOriginServerTs: 1743705332000,
    mockMsgContent: MockMsgContent(mockBody: 'Thanks for the help!'),
  ),
  isBookmarked: true,
);

final mockChatItem9 = MockChatItem(
  roomId: 'room-9',
  isDM: false,
  displayName: 'Team Updates',
  lastMessage: MockTimelineEventItem(
    mockEventId: 'event-9',
    mockSenderId: 'Emily Taylor',
    mockOriginServerTs: 1743706332000,
    mockMsgContent: MockMsgContent(mockBody: 'New features deployed'),
  ),
  isBookmarked: true,
);

final mockChatItem10 = MockChatItem(
  roomId: 'room-10',
  isDM: true,
  displayName: 'Emma Davis',
  lastMessage: MockTimelineEventItem(
    mockEventId: 'event-10',
    mockSenderId: 'Emma Davis',
    mockOriginServerTs: 1743707332000,
    mockMsgContent: MockMsgContent(mockBody: "Let me know when you're free"),
  ),
);

final mockChatItem11 = MockChatItem(
  roomId: 'room-11',
  isDM: true,
  displayName: 'Alex Thompson',
  lastMessage: MockTimelineEventItem(
    mockEventId: 'event-11',
    mockSenderId: 'Alex Thompson',
    mockOriginServerTs: 1743708332000,
    mockMsgContent: MockMsgContent(mockBody: 'See you at the meeting'),
  ),
);

final mockChatItem12 = MockChatItem(
  roomId: 'room-12',
  isDM: false,
  displayName: 'Marketing Team',
  lastMessage: MockTimelineEventItem(
    mockEventId: 'event-12',
    mockSenderId: 'Christopher Anderson',
    mockOriginServerTs: 1743709332000,
    mockMsgContent: MockMsgContent(mockBody: 'Campaign approved'),
  ),
);

final mockChatItem13 = MockChatItem(
  roomId: 'room-13',
  isDM: true,
  displayName: 'Lisa Park',
  lastMessage: MockTimelineEventItem(
    mockEventId: 'event-13',
    mockSenderId: 'Lisa Park',
    mockOriginServerTs: 1743710332000,
    mockMsgContent: MockMsgContent(mockBody: 'Document reviewed'),
  ),
);

final mockChatItem14 = MockChatItem(
  roomId: 'room-14',
  isDM: false,
  displayName: 'Product Feedback',
  lastMessage: MockTimelineEventItem(
    mockEventId: 'event-14',
    mockSenderId: 'Daniel Martinez',
    mockOriginServerTs: 1743711332000,
    mockMsgContent: MockMsgContent(mockBody: 'New feature requests'),
  ),
);

final mockChatItem15 = MockChatItem(
  roomId: 'room-15',
  isDM: true,
  displayName: 'David Miller',
  lastMessage: MockTimelineEventItem(
    mockEventId: 'event-15z',
    mockSenderId: 'David Miller',
    mockOriginServerTs: 1743712332000,
    mockMsgContent: MockMsgContent(mockBody: 'Task completed'),
  ),
);
