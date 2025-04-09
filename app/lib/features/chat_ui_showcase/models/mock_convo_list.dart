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
  MockRoom('mock-room-1', Future.value(MockOptionString('Mock Room 1'))),
  MockRoom('mock-room-2', Future.value(MockOptionString('Mock Room 2'))),
  MockRoom('mock-room-3', Future.value(MockOptionString('Mock Room 3'))),
  MockRoom('mock-room-4', Future.value(MockOptionString('Mock Room 4'))),
  MockRoom('mock-room-5', Future.value(MockOptionString('Mock Room 5'))),
  MockRoom('mock-room-6', Future.value(MockOptionString('Mock Room 6'))),
  MockRoom('mock-room-7', Future.value(MockOptionString('Mock Room 7'))),
];

final List<MockConvo> mockConvoList = [
  MockConvo('mock-room-1'),
  MockConvo('mock-room-2'),
  MockConvo('mock-room-3'),
  MockConvo('mock-room-4'),
  MockConvo('mock-room-5'),
  MockConvo('mock-room-6'),
  MockConvo('mock-room-7'),
];
