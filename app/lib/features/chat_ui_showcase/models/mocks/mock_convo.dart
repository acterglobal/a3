import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockTimelineItem extends Mock implements TimelineItem {
  final MockTimelineEventItem? mockTimelineEventItem;

  MockTimelineItem({this.mockTimelineEventItem});

  @override
  TimelineEventItem? eventItem() => mockTimelineEventItem;
}

class MockUserId extends Mock implements UserId {
  final String? mockUserId;
  MockUserId({this.mockUserId});

  @override
  String toString() => mockUserId ?? 'userId';
}

class MockMembershipContent extends Mock implements MembershipContent {
  final String? mockUserId;
  final String? mockMembershipType;
  MockMembershipContent({this.mockUserId, this.mockMembershipType});

  @override
  UserId userId() => MockUserId(mockUserId: mockUserId);

  @override
  String change() => mockMembershipType ?? '';
}

class MockProfileContent extends Mock implements ProfileContent {
  final String? mockUserId;
  final String? mockDisplayNameChange;
  final String? mockDisplayNameOldVal;
  final String? mockDisplayNameNewVal;
  final String? mockAvatarUrlChange;
  MockProfileContent({
    this.mockUserId,
    this.mockDisplayNameChange,
    this.mockDisplayNameOldVal,
    this.mockDisplayNameNewVal,
    this.mockAvatarUrlChange,
  });

  @override
  UserId userId() => MockUserId(mockUserId: mockUserId);

  @override
  String? displayNameChange() => mockDisplayNameChange;

  @override
  String? avatarUrlChange() => mockAvatarUrlChange;

  @override
  String? displayNameOldVal() => mockDisplayNameOldVal;

  @override
  String? displayNameNewVal() => mockDisplayNameNewVal;
}

class MockTimelineEventItem extends Mock implements TimelineEventItem {
  final String? mockEventId;
  final String? mockSenderId;
  final int? mockOriginServerTs;
  final String? mockEventType;
  final MsgContent? mockMsgContent;
  final String? mockMsgType;
  final MembershipContent? mockMembershipContent;
  final ProfileContent? mockProfileContent;
  MockTimelineEventItem({
    this.mockEventId,
    this.mockSenderId,
    this.mockOriginServerTs,
    this.mockEventType,
    this.mockMsgContent,
    this.mockMsgType,
    this.mockMembershipContent,
    this.mockProfileContent,
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

  @override
  String msgType() => mockMsgType ?? 'm.text';

  @override
  MembershipContent? membershipContent() => mockMembershipContent;

  @override
  ProfileContent? profileContent() => mockProfileContent;
}

class MockMsgContent extends Mock implements MsgContent {
  final String? mockBody;
  MockMsgContent({this.mockBody});

  @override
  String body() => mockBody ?? 'body';
}

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
