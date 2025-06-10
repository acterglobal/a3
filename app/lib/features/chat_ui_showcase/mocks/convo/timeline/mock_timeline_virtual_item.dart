import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockTimelineVirtualItem extends Mock implements TimelineVirtualItem {
  final String? mockEventId;
  final String? mockEventType;
  final String? mockDesc;

  MockTimelineVirtualItem({
    this.mockEventId,
    this.mockEventType,
    this.mockDesc,
  });

  @override
  String eventType() => mockEventType ?? 'Unknown';

  @override
  String? desc() => mockDesc;
}
