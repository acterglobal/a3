import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockTimelineEventItem extends Mock implements TimelineEventItem {
  final String? mockEventId;
  final String? mockSenderId;
  final int? mockOriginServerTs;
  final String? mockEventType;
  final MsgContent? mockMsgContent;

  MockTimelineEventItem({
    this.mockEventId,
    this.mockSenderId,
    this.mockOriginServerTs,
    this.mockEventType,
    this.mockMsgContent,
  });

  @override
  String eventId() => mockEventId ?? 'eventId';

  @override
  String sender() => mockSenderId ?? 'senderId';

  @override
  int originServerTs() => mockOriginServerTs ?? 1744018801000;

  @override
  MsgContent? msgContent() => mockMsgContent ?? MockMsgContent();

  @override
  String eventType() => mockEventType ?? 'm.room.message';
}

class MockMsgContent extends Mock implements MsgContent {
  final String? mockBody;

  MockMsgContent({this.mockBody});

  @override
  String body() => mockBody ?? 'body';
}
