import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';
import 'mock_basics.dart';
import 'mock_invites.dart' as invites;

class MockMember extends Mock implements Member {
  final String _userId;
  final bool _canString;

  MockMember({String? userId, bool? canString}) 
    : _userId = userId ?? 'test_user_id',
      _canString = canString ?? false;

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

  @override
  bool canString(String action) => _canString;
}
