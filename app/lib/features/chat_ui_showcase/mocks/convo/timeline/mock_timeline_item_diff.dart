import 'package:acter/features/chat_ui_showcase/mocks/convo/timeline/mock_ffi_list_timeline_item.dart';
import 'package:acter/features/chat_ui_showcase/mocks/convo/timeline/mock_timeline_item.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

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
