import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockTimelineItem extends Mock implements TimelineItem {}

class MockConvo extends Mock implements Convo {
  final String mockConvoId;
  final bool mockIsDm;
  final bool mockIsBookmarked;
  final int mockNumUnreadNotificationCount;
  final int mockNumUnreadMentions;
  final int mockNumUnreadMessages;
  final MockTimelineItem? mockTimelineItem;

  MockConvo({
    required this.mockConvoId,
    this.mockIsDm = true,
    this.mockIsBookmarked = true,
    this.mockNumUnreadNotificationCount = 0,
    this.mockNumUnreadMentions = 0,
    this.mockNumUnreadMessages = 0,
    this.mockTimelineItem,
  });

  @override
  String getRoomIdStr() => mockConvoId;

  @override
  bool isDm() => mockIsDm;

  @override
  bool isBookmarked() => mockIsBookmarked;

  @override
  int numUnreadNotificationCount() => mockNumUnreadNotificationCount;

  @override
  int numUnreadMentions() => mockNumUnreadMentions;

  @override
  int numUnreadMessages() => mockNumUnreadMessages;

  @override
  TimelineItem? latestMessage() => mockTimelineItem;
}
