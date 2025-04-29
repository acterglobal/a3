import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';
import '../../../helpers/mock_basics.dart';

class MockMembershipContent extends Mock implements MembershipContent {
  final String? mockUserId;
  final String? mockChange;

  MockMembershipContent({
    this.mockUserId,
    this.mockChange,
  });

  @override
  String change() => mockChange ?? 'mock-change';

  @override
  UserId userId() => MockUserId(mockUserId ?? 'mock-user-id');
}