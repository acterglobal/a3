import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';
import '../../../helpers/mock_basics.dart';

class MockMembershipContent extends Mock implements MembershipContent {
  final String? mockUserId;
  final String? mockAvatarUrl;
  final String? mockDisplayName;
  final String? mockReason;
  final String? mockRoomId;
  final int? mockOriginServerTs;

  MockMembershipContent({
    this.mockUserId,
    this.mockAvatarUrl,
    this.mockDisplayName,
    this.mockReason,
    this.mockRoomId,
    this.mockOriginServerTs,
  });

  @override
  String change() => 'mock-change';

  @override
  UserId userId() => MockUserId(mockUserId ?? 'mock-user-id');

  @override
  String userIdStr() => mockUserId ?? 'mock-user-id';

  @override
  String? avatarUrl() => mockAvatarUrl;

  @override
  String? displayName() => mockDisplayName;

  @override
  String? reason() => mockReason;

  @override
  RoomId roomId() => MockRoomId(mockRoomId ?? 'mock-room-id');

  @override
  int originServerTs() => mockOriginServerTs ?? 1234567890;
}