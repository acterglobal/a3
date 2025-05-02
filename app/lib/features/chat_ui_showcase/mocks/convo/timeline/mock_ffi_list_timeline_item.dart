import 'package:acter/features/chat_ui_showcase/mocks/convo/timeline/mock_timeline_item.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockFfiListTimelineItem extends Mock implements FfiListTimelineItem {
  final List<MockTimelineItem> timelineItems;

  MockFfiListTimelineItem({required this.timelineItems});

  @override
  List<MockTimelineItem> toList({bool growable = false}) =>
      timelineItems.toList(growable: growable);
}
