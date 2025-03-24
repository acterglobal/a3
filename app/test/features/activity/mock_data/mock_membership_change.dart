import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockMembershipChange extends Mock implements MembershipChange {
  final String? mockUserId;
  final String? mockAvatarUrl;
  final String? mockDisplayName;
  final String? mockReason;

  MockMembershipChange({
    this.mockUserId,
    this.mockAvatarUrl,
    this.mockDisplayName,
    this.mockReason,
  });

  @override
  String userIdStr() => mockUserId ?? 'mock-user-id';

  @override
  String? avatarUrl() => mockAvatarUrl;

  @override
  String? displayName() => mockDisplayName;

  @override
  String? reason() => mockReason;

  @override
  void drop() {
    // No-op for mock implementation
  }
}