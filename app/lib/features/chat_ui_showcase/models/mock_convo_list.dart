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
    mockDisplayName: Future.value(MockOptionString(mockText: 'Mock Room 1')),
  ),
  MockRoom(
    mockRoomId: 'mock-room-2',
    mockDisplayName: Future.value(MockOptionString(mockText: 'Mock Room 2')),
  ),
  MockRoom(
    mockRoomId: 'mock-room-3',
    mockDisplayName: Future.value(MockOptionString(mockText: 'Mock Room 3')),
  ),
  MockRoom(
    mockRoomId: 'mock-room-4',
    mockDisplayName: Future.value(MockOptionString(mockText: 'Mock Room 4')),
  ),
  MockRoom(
    mockRoomId: 'mock-room-5',
    mockDisplayName: Future.value(MockOptionString(mockText: 'Mock Room 5')),
  ),
  MockRoom(
    mockRoomId: 'mock-room-6',
    mockDisplayName: Future.value(MockOptionString(mockText: 'Mock Room 6')),
  ),
  MockRoom(
    mockRoomId: 'mock-room-7',
    mockDisplayName: Future.value(MockOptionString(mockText: 'Mock Room 7')),
  ),
];

final List<MockConvo> mockConvoList = [
  MockConvo(mockConvoId: 'mock-room-1'),
  MockConvo(mockConvoId: 'mock-room-2'),
  MockConvo(mockConvoId: 'mock-room-3'),
  MockConvo(mockConvoId: 'mock-room-4'),
  MockConvo(mockConvoId: 'mock-room-5'),
  MockConvo(mockConvoId: 'mock-room-6'),
  MockConvo(mockConvoId: 'mock-room-7'),
];
