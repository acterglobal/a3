import 'package:acter/common/providers/notifiers/room_notifiers.dart';
import 'package:acter/common/providers/notifiers/space_notifiers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';
import 'package:mockito/mockito.dart';

class MockRoomAvatarInfoNotifier extends FamilyNotifier<AvatarInfo, String>
    with Mock
    implements RoomAvatarInfoNotifier {
  @override
  AvatarInfo build(arg) => AvatarInfo(uniqueId: arg);
}

class RetryMockAsyncSpaceNotifier extends FamilyAsyncNotifier<Space?, String>
    with Mock
    implements AsyncMaybeSpaceNotifier {
  bool shouldFail = true;

  @override
  Future<MockSpace> build(String arg) async {
    if (shouldFail) {
      // toggle failure so the retry works
      shouldFail = !shouldFail;
      throw 'Expected fail: Space not loaded';
    }
    return MockSpace();
  }
}

class MockSpace extends Fake implements Space {}

class MockSpaceHierarchyRoomInfo extends Fake
    implements SpaceHierarchyRoomInfo {
  final String roomId;
  final String? roomName;
  final String joinRule;
  final String serverName;
  final bool isSuggested;

  MockSpaceHierarchyRoomInfo({
    required this.roomId,
    this.roomName,
    this.joinRule = 'Private',
    this.isSuggested = false,
    this.serverName = '',
  });

  @override
  String roomIdStr() => roomId;

  @override
  String? name() => roomName;

  @override
  String joinRuleStr() => joinRule;

  @override
  String viaServerName() => serverName;

  @override
  bool suggested() => isSuggested;
}
