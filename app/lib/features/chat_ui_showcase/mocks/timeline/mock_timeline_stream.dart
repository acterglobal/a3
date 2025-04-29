import 'package:acter/features/chat_ui_showcase/models/mocks/convo/mock_convo.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockFfiListTimelineItem extends Mock implements FfiListTimelineItem {
  final List<MockTimelineItem> timelineItems;

  MockFfiListTimelineItem({required this.timelineItems});

  @override
  List<MockTimelineItem> toList({bool growable = false}) =>
      timelineItems.toList(growable: growable);
}

class MockTimelineItemDiff extends Mock implements TimelineItemDiff {
  final String mockAction;
  final MockFfiListTimelineItem? mockTimelineItemList;
  final int? mockIndex;
  final MockTimelineItem? mockTimelineItem;

  MockTimelineItemDiff({
    this.mockAction = 'Append',
    this.mockTimelineItemList,
    this.mockIndex,
    this.mockTimelineItem,
  });

  @override
  String action() => mockAction;

  @override
  FfiListTimelineItem? values() => mockTimelineItemList;

  @override
  int? index() => mockIndex;

  @override
  TimelineItem? value() => mockTimelineItem;

  @override
  void drop() {}
}

class MockTimelineStream extends Mock implements TimelineStream {
  final List<MockTimelineItemDiff> mockTimelineItemDiffs;
  final bool mockPaginateBackwards;
  final bool mockSendMessage;
  final bool mockEditMessage;
  final bool mockReplyMessage;
  final bool mockMarkAsRead;
  final bool mockToggleReaction;
  final bool mockDrop;

  MockTimelineStream({
    required this.mockTimelineItemDiffs,
    this.mockPaginateBackwards = true,
    this.mockSendMessage = true,
    this.mockEditMessage = true,
    this.mockReplyMessage = true,
    this.mockMarkAsRead = true,
    this.mockToggleReaction = true,
    this.mockDrop = true,
  });

  @override
  Stream<TimelineItemDiff> messagesStream() =>
      Stream.fromIterable(mockTimelineItemDiffs.map((diff) => diff));

  @override
  Future<bool> paginateBackwards(int count) =>
      Future.value(mockPaginateBackwards);

  @override
  Future<bool> sendMessage(MsgDraft draft) => Future.value(mockSendMessage);

  @override
  Future<bool> editMessage(String eventId, MsgDraft draft) =>
      Future.value(mockEditMessage);

  @override
  Future<bool> replyMessage(String eventId, MsgDraft draft) =>
      Future.value(mockReplyMessage);

  @override
  Future<bool> markAsRead(bool public) => Future.value(mockMarkAsRead);

  @override
  Future<bool> toggleReaction(String eventId, String key) =>
      Future.value(mockToggleReaction);

  @override
  void drop() => mockDrop;
}
