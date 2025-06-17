import 'dart:math';
import 'package:acter/features/chat_ui_showcase/mocks/convo/timeline/mock_timeline_event_item.dart';
import 'package:acter/features/chat_ui_showcase/mocks/convo/timeline/mock_timeline_virtual_item.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockTimelineItem extends Mock implements TimelineItem {
  final MockTimelineEventItem? mockTimelineEventItem;
  final MockTimelineVirtualItem? mockTimelineVirtualItem;

  MockTimelineItem({this.mockTimelineEventItem, this.mockTimelineVirtualItem});

  @override
  TimelineEventItem? eventItem() => mockTimelineEventItem;

  @override
  TimelineVirtualItem? virtualItem() => mockTimelineVirtualItem;

  @override
  String uniqueId() =>
      mockTimelineEventItem?.mockEventId ??
      mockTimelineVirtualItem?.mockEventId ??
      Random().nextInt(1000000).toString();
}
