import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mock_tasks_providers.dart';

class MockSuperInvites extends Mock implements SuperInvites {
  @override
  SuperInvitesTokenUpdateBuilder newTokenUpdater() =>
      MockSuperInvitesTokenUpdateBuilder();
}

class MockSuperInvitesTokenUpdateBuilder extends Mock
    implements SuperInvitesTokenUpdateBuilder {}

class MockSuperInviteToken extends Mock implements SuperInviteToken {
  final MockFfiListFfiString? mockFfiListFfiString;

  MockSuperInviteToken({this.mockFfiListFfiString});

  @override
  String token() => 'test_invite_code';

  @override
  FfiListFfiString rooms() => mockFfiListFfiString ?? MockFfiListFfiString();

  @override
  int acceptedCount() => 3;

  @override
  bool createDm() => true;

  @override
  SuperInvitesTokenUpdateBuilder updateBuilder() =>
      MockSuperInvitesTokenUpdateBuilder();
}
