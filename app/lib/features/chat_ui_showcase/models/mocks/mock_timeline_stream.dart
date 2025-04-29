import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockTimelineItemDiff extends Mock implements TimelineItemDiff {
  final String mockEventId;
  final String mockSenderId;
  final int mockOriginServerTs;
  final String mockEventType;
  final String mockMsgType;

  MockTimelineItemDiff({
    required this.mockEventId,
    required this.mockSenderId,
    required this.mockOriginServerTs,
    required this.mockEventType,
    required this.mockMsgType,
  });
}

class MockTimelineStream extends Mock implements TimelineStream {
  MockTimelineStream();

  @override
  Stream<TimelineItemDiff> messagesStream() => Stream<TimelineItemDiff>.empty();

  @override
  Future<bool> paginateBackwards(int count) => Future.value(true);

  @override
  Future<bool> sendMessage(MsgDraft draft) => Future.value(true);

  @override
  Future<bool> editMessage(String eventId, MsgDraft draft) =>
      Future.value(true);

  @override
  Future<bool> replyMessage(String eventId, MsgDraft draft) =>
      Future.value(true);

  @override
  Future<bool> markAsRead(bool public) => Future.value(true);

  @override
  Future<bool> toggleReaction(String eventId, String key) => Future.value(true);

  @override
  void drop() {}
}
