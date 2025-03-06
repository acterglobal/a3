import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockActivity extends Mock implements Activity {
  final String mockType;
  final String mockSenderId;
  final String mockRoomId;
  final ActivityObject? mockObject;
  final MsgContent? mockMsgContent;
  final int mockOriginServerTs;

  MockActivity({
    required this.mockType,
    required this.mockSenderId,
    required this.mockRoomId,
    required this.mockObject,
    required this.mockMsgContent,
    required this.mockOriginServerTs,
  });

  @override
  String typeStr() => mockType;

  @override
  String senderIdStr() => mockSenderId;

  @override
  String roomIdStr() => mockRoomId;

  @override
  ActivityObject? object() => mockObject;

  @override
  MsgContent? msgContent() => mockMsgContent;

  @override
  int originServerTs() => mockOriginServerTs;
}
