import 'package:acter/features/chat_ui_showcase/mocks/general/mock_userId.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockMember extends Mock implements Member {
  final String mockMemberId;
  final String mockRoomId;
  final String mockMembershipStatusStr;
  final bool mockCanString;

  MockMember({
    required this.mockMemberId,
    required this.mockRoomId,
    required this.mockMembershipStatusStr,
    required this.mockCanString,
  });

  @override
  UserId userId() => MockUserId(mockUserId: mockMemberId);

  @override
  String roomIdStr() => mockRoomId;

  @override
  String membershipStatusStr() => mockMembershipStatusStr;

  @override
  bool canString(String permission) => mockCanString;
}
