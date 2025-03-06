import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockActivity extends Mock implements Activity {
  final String mockType;
  final String? mockName;
  final String? mockSubType;
  final String? mockSenderId;
  final String? mockRoomId;
  final ActivityObject? mockObject;
  final MsgContent? mockMsgContent;
  final int? mockOriginServerTs;
  final RefDetails? mockRefDetails;

  MockActivity({
    required this.mockType,
    this.mockName,
    this.mockSubType,
    this.mockSenderId,
    this.mockRoomId,
    this.mockObject,
    this.mockMsgContent,
    this.mockOriginServerTs,
    this.mockRefDetails,
  });

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
  int originServerTs() => mockOriginServerTs ?? 1234567890;

  @override
  RefDetails? refDetails() => mockRefDetails;
}
