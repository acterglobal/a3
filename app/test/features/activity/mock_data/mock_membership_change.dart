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
}