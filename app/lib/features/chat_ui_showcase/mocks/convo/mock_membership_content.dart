import 'package:acter/features/chat_ui_showcase/mocks/general/mock_userId.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockMembershipContent extends Mock implements MembershipContent {
  final String? mockUserId;
  final String? mockMembershipType;
  MockMembershipContent({this.mockUserId, this.mockMembershipType});

  @override
  UserId userId() => MockUserId(mockUserId: mockUserId);

  @override
  String change() => mockMembershipType ?? '';
}
