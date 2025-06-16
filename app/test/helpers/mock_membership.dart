import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';
import 'mock_basics.dart';
import 'mock_invites.dart' as invites;

class MockMember extends Mock implements Member {
  final String _userId;

  MockMember({String? userId}) : _userId = userId ?? 'test_user_id';

  @override
  UserId userId() => MockUserId(_userId);

  @override
  UserProfile getProfile() {
    return invites.MockUserProfile(
      userId: _userId,
      displayName: 'Test Member',
      sharedRooms: [],
    );
  }
}
