import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockActivity extends Mock implements Activity {
  final String mockActivityId;
  final String mockType;
  final String? mockName;
  final String? mockSubType;
  final String? mockSenderId;
  final String? mockRoomId;
  final ActivityObject? mockObject;
  final MsgContent? mockMsgContent;
  final MembershipContent? mockMembershipContent;
  final RoomTopicContent? mockRoomTopicContent;
  final RefDetails? mockRefDetails;
  final TitleContent? mockTitleContent;
  final DescriptionContent? mockDescriptionContent;
  final int? mockOriginServerTs;

  MockActivity({
    required this.mockActivityId,
    required this.mockType,
    this.mockName,
    this.mockSubType,
    this.mockSenderId,
    this.mockRoomId,
    this.mockObject,
    this.mockMsgContent,
    this.mockMembershipContent,
    this.mockRoomTopicContent,
    this.mockRefDetails,
    this.mockTitleContent,
    this.mockDescriptionContent,
    this.mockOriginServerTs,
  });

  @override
  String eventIdStr() => mockActivityId;

  @override
  String typeStr() => mockType;

  @override
  String? name() => mockName;

  @override
  String? subTypeStr() => mockSubType;

  @override
  String senderIdStr() => mockSenderId ?? 'sender-id';

  @override
  String roomIdStr() => mockRoomId ?? 'room-id';

  @override
  ActivityObject? object() => mockObject;

  @override
  MsgContent? msgContent() => mockMsgContent;

  @override
  MembershipContent? membershipContent() => mockMembershipContent;

  @override
  RoomTopicContent? roomTopicContent() => mockRoomTopicContent;

  @override
  RefDetails? refDetails() => mockRefDetails;

  @override
  TitleContent? titleContent() => mockTitleContent;

  @override
  DescriptionContent? descriptionContent() => mockDescriptionContent;

  @override
  int originServerTs() => mockOriginServerTs ?? DateTime.now().millisecondsSinceEpoch;

  // Default implementations for optional methods
  @override
  DateContent? dateContent() => null;

  @override
  DateTimeRangeContent? dateTimeRangeContent() => null;

  @override
  RoomAvatarContent? roomAvatarContent() => null;

  @override
  RoomNameContent? roomNameContent() => null;

  @override
  String? roomName() => null;

  @override
  String? roomAvatar() => null;
}
