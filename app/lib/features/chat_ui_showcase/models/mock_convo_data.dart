class MockConvo {
  final String roomId;
  final bool isDM;
  final String displayName;
  final String lastMessage;
  final int lastMessageTimestamp;
  final String? lastMessageSenderDisplayName;
  final bool isUnread;
  final int unreadCount;
  final bool isTyping;
  final bool isMuted;
  final bool isBookmarked;

  MockConvo({
    required this.roomId,
    required this.isDM,
    required this.displayName,
    required this.lastMessage,
    required this.lastMessageTimestamp,
    this.lastMessageSenderDisplayName,
    this.isUnread = false,
    this.unreadCount = 0,
    this.isTyping = false,
    this.isMuted = false,
    this.isBookmarked = false,
  });
}

final mockConvo1 = MockConvo(
  roomId: 'room-1',
  isDM: true,
  displayName: 'John Doe',
  lastMessage: 'Hello, how are you?',
  lastMessageTimestamp: 1743698332000,
  isUnread: true,
  unreadCount: 1,
  isMuted: true,
  isBookmarked: true,
);

final mockConvo2 = MockConvo(
  roomId: 'room-2',
  isDM: false,
  displayName: 'Social Media',
  lastMessage: 'Hello, how are you?',
  lastMessageTimestamp: 1743699332000,
  lastMessageSenderDisplayName: 'Smith',
  isUnread: true,
  unreadCount: 2,
  isTyping: true,
  isMuted: true,
);

final mockConvo3 = MockConvo(
  roomId: 'room-2',
  isDM: false,
  displayName: 'Acter Tech',
  lastMessage: 'Hello, how are you?',
  lastMessageTimestamp: 1743700332000,
  lastMessageSenderDisplayName: 'Benjamin',
  isUnread: true,
  unreadCount: 2,
);

final mockConvo4 = MockConvo(
  roomId: 'room-4',
  isDM: false,
  displayName: 'Acter Team',
  lastMessage: 'Hello, how are you?',
  lastMessageTimestamp: 1743701332000,
  lastMessageSenderDisplayName: 'Diana Smith',
  isMuted: true,
  isBookmarked: true,
);

final mockConvo5 = MockConvo(
  roomId: 'room-5',
  isDM: true,
  displayName: 'Kumarpalsinh Rana',
  lastMessage: 'Hello, how are you?',
  lastMessageTimestamp: 1743702332000,
  isTyping: true,
);

final mockConvo6 = MockConvo(
  roomId: 'room-6',
  isDM: true,
  displayName: 'Sarah Wilson',
  lastMessage: 'Can we meet tomorrow?',
  lastMessageTimestamp: 1743703332000,
);

final mockConvo7 = MockConvo(
  roomId: 'room-7',
  isDM: false,
  displayName: 'Project Alpha',
  lastMessage: 'Meeting notes attached',
  lastMessageTimestamp: 1743704332000,
  lastMessageSenderDisplayName: 'John Doe',
);

final mockConvo8 = MockConvo(
  roomId: 'room-8',
  isDM: true,
  displayName: 'Michael Chen',
  lastMessage: 'Thanks for the help!',
  lastMessageTimestamp: 1743705332000,
  isBookmarked: true,
);

final mockConvo9 = MockConvo(
  roomId: 'room-9',
  isDM: false,
  displayName: 'Team Updates',
  lastMessage: 'New features deployed',
  lastMessageTimestamp: 1743706332000,
  lastMessageSenderDisplayName: 'John Doe',
  isBookmarked: true,
);

final mockConvo10 = MockConvo(
  roomId: 'room-10',
  isDM: true,
  displayName: 'Emma Davis',
  lastMessage: 'Let me know when you\'re free',
  lastMessageTimestamp: 1743707332000,
);

final mockConvo11 = MockConvo(
  roomId: 'room-11',
  isDM: true,
  displayName: 'Alex Thompson',
  lastMessage: 'See you at the meeting',
  lastMessageTimestamp: 1743708332000,
  isUnread: false,
);

final mockConvo12 = MockConvo(
  roomId: 'room-12',
  isDM: false,
  displayName: 'Marketing Team',
  lastMessage: 'Campaign approved',
  lastMessageTimestamp: 1743709332000,
  isUnread: false,
  lastMessageSenderDisplayName: 'Marketing Lead',
);

final mockConvo13 = MockConvo(
  roomId: 'room-13',
  isDM: true,
  displayName: 'Lisa Park',
  lastMessage: 'Document reviewed',
  lastMessageTimestamp: 1743710332000,
  isUnread: false,
);

final mockConvo14 = MockConvo(
  roomId: 'room-14',
  isDM: false,
  displayName: 'Product Feedback',
  lastMessage: 'New feature requests',
  lastMessageTimestamp: 1743711332000,
  isUnread: false,
  lastMessageSenderDisplayName: 'Product Manager',
);

final mockConvo15 = MockConvo(
  roomId: 'room-15',
  isDM: true,
  displayName: 'David Miller',
  lastMessage: 'Task completed',
  lastMessageTimestamp: 1743712332000,
  isUnread: false,
);
