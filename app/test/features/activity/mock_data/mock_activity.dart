import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockActivity extends Mock implements Activity {
  final String mockType;
  final String? mockSenderId;
  final String? mockRoomId;
  final ActivityObject? mockObject;
  final MsgContent? mockMsgContent;
  final int? mockOriginServerTs;
  final RefDetails? mockRefDetails;

  MockActivity({
    required this.mockType,
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
