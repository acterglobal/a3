import 'package:acter/features/chat_ui_showcase/mocks/general/mock_ffi_list_ffi_string.dart';
import 'package:acter/features/chat_ui_showcase/mocks/general/mock_msg_content.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockTimelineEventItem extends Mock implements TimelineEventItem {
  final String? mockEventId;
  final String? mockSenderId;
  final int? mockOriginServerTs;
  final String? mockEventType;
  final MsgContent? mockMsgContent;
  final String? mockMsgType;
  final MembershipContent? mockMembershipContent;
  final ProfileContent? mockProfileContent;
  final MockFfiListFfiString? mockReactionKeys;
  final bool? mockWasEdited;

  MockTimelineEventItem({
    this.mockEventId,
    this.mockSenderId,
    this.mockOriginServerTs,
    this.mockEventType,
    this.mockMsgContent,
    this.mockMsgType,
    this.mockMembershipContent,
    this.mockProfileContent,
    this.mockReactionKeys,
    this.mockWasEdited,
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

  @override
  FfiListFfiString reactionKeys() =>
      mockReactionKeys ?? MockFfiListFfiString(mockStrings: []);

  @override
  bool wasEdited() => mockWasEdited ?? false;
}
