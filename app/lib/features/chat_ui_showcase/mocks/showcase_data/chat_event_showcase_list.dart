import 'package:acter/features/chat_ui_showcase/mocks/convo/timeline/mock_timeline_event_item.dart';
import 'package:acter/features/chat_ui_showcase/mocks/convo/timeline/mock_timeline_item.dart';

List<MockTimelineItem> mockChatEventList = [
  MockTimelineItem(
    mockTimelineEventItem: MockTimelineEventItem(
      mockEventId: 'event_id_1',
      mockSenderId: '@emily:acter.global',
      mockOriginServerTs: 1744182966000,
      mockEventType: 'm.room.message',
      mockMsgType: 'm.text',
    ),
  ),
];
