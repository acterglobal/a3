import 'package:acter/features/chat_ui_showcase/mocks/convo/timeline/mock_timeline_item.dart';
import 'package:acter/features/chat_ui_showcase/mocks/convo/timeline/mock_timeline_stream.dart';
import 'package:acter/features/chat_ui_showcase/mocks/general/mock_option_compose_draft.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockConvo extends Mock implements Convo {
  final String mockConvoId;
  final bool mockIsDm;
  final bool mockIsBookmarked;
  final int mockNumUnreadNotificationCount;
  final int mockNumUnreadMentions;
  final int mockNumUnreadMessages;
  final MockTimelineItem? mockTimelineItem;
  final MockTimelineStream mockTimelineStream;
  final MockOptionComposeDraft? mockMsgDraft;

  MockConvo({
    required this.mockConvoId,
    required this.mockTimelineStream,
    this.mockIsDm = true,
    this.mockIsBookmarked = true,
    this.mockNumUnreadNotificationCount = 0,
    this.mockNumUnreadMentions = 0,
    this.mockNumUnreadMessages = 0,
    this.mockTimelineItem,
    this.mockMsgDraft,
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

  @override
  TimelineStream timelineStream() => mockTimelineStream;

  @override
  Future<OptionComposeDraft> msgDraft() => Future.value(mockMsgDraft);
}
