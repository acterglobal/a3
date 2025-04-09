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
  ),
  MockRoom(
    mockRoomId: 'mock-room-2',
    mockDisplayName: 'Mock Room 2',
    mockNotificationMode: 'muted',
  ),
  MockRoom(mockRoomId: 'mock-room-3', mockDisplayName: 'Mock Room 3'),
  MockRoom(mockRoomId: 'mock-room-4', mockDisplayName: 'Mock Room 4'),
  MockRoom(mockRoomId: 'mock-room-5', mockDisplayName: 'Mock Room 5'),
  MockRoom(mockRoomId: 'mock-room-6', mockDisplayName: 'Mock Room 6'),
  MockRoom(mockRoomId: 'mock-room-7', mockDisplayName: 'Mock Room 7'),
  MockRoom(mockRoomId: 'mock-room-8', mockDisplayName: 'Mock Room 8'),
  MockRoom(mockRoomId: 'mock-room-9', mockDisplayName: 'Mock Room 9'),
  MockRoom(mockRoomId: 'mock-room-10', mockDisplayName: 'Mock Room 10'),
];

final List<MockConvo> mockConvoList = [
  MockConvo(
    mockConvoId: 'mock-room-1',
    mockIsDm: true,
    mockIsBookmarked: true,
    mockNumUnreadNotificationCount: 4,
    mockNumUnreadMentions: 2,
    mockNumUnreadMessages: 2,
  ),
  MockConvo(
    mockConvoId: 'mock-room-2',
    mockIsDm: false,
    mockIsBookmarked: true,
    mockNumUnreadNotificationCount: 1,
    mockNumUnreadMentions: 1,
    mockNumUnreadMessages: 1,
  ),
  MockConvo(mockConvoId: 'mock-room-3', mockIsDm: true, mockIsBookmarked: true),
  MockConvo(
    mockConvoId: 'mock-room-4',
    mockIsDm: false,
    mockIsBookmarked: false,
  ),
  MockConvo(
    mockConvoId: 'mock-room-5',
    mockIsDm: true,
    mockIsBookmarked: true,
    mockNumUnreadNotificationCount: 3,
    mockNumUnreadMentions: 3,
    mockNumUnreadMessages: 3,
  ),
  MockConvo(
    mockConvoId: 'mock-room-6',
    mockIsDm: false,
    mockIsBookmarked: false,
  ),
  MockConvo(
    mockConvoId: 'mock-room-7',
    mockIsDm: false,
    mockIsBookmarked: false,
  ),
  MockConvo(
    mockConvoId: 'mock-room-8',
    mockIsDm: true,
    mockIsBookmarked: false,
  ),
  MockConvo(
    mockConvoId: 'mock-room-9',
    mockIsDm: false,
    mockIsBookmarked: false,
  ),
  MockConvo(
    mockConvoId: 'mock-room-10',
    mockIsDm: false,
    mockIsBookmarked: false,
  ),
];
