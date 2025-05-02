import 'package:acter/features/chat_ui_showcase/mocks/general/mock_userId.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

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
