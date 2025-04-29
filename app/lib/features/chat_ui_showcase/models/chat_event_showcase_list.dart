import 'package:acter/features/chat_ui_showcase/models/mocks/mock_timeline_stream.dart';

List<MockTimelineItemDiff> mockChatEventList = [
  MockTimelineItemDiff(
    mockEventId: 'event_id_1',
    mockSenderId: '@emily:acter.global',
    mockOriginServerTs: 1744182966000,
    mockEventType: 'm.room.message',
    mockMsgType: 'm.text',
  ),
  MockTimelineItemDiff(
    mockEventId: 'event_id_2',
    mockSenderId: '@sarah:acter.global',
    mockOriginServerTs: 1744182966000,
    mockEventType: 'm.room.message',
    mockMsgType: 'm.text',
  ),
  MockTimelineItemDiff(
    mockEventId: 'event_id_3',
    mockSenderId: '@michael:acter.global',
    mockOriginServerTs: 1744182966000,
    mockEventType: 'm.room.message',
    mockMsgType: 'm.text',
  ),
];
