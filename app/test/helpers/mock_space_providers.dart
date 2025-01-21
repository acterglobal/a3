import 'package:acter/common/providers/notifiers/room_notifiers.dart';
import 'package:acter/common/providers/notifiers/space_notifiers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockRoomAvatarInfoNotifier extends FamilyNotifier<AvatarInfo, String>
    with Mock
    implements RoomAvatarInfoNotifier {
  final Map<String, AvatarInfo> items;

  MockRoomAvatarInfoNotifier({this.items = const {}});

  @override
  AvatarInfo build(arg) => items[arg] ?? AvatarInfo(uniqueId: arg);
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

class MockSpace extends Mock implements Space {
  final String id;
  final bool bookmarked;

  MockSpace({
    this.id = 'id',
    this.bookmarked = false,
  });

  @override
  String getRoomIdStr() => id;

  @override
  bool isBookmarked() => bookmarked;
}

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

class MockSpaceListNotifiers extends Notifier<List<Space>>
    with Mock
    implements SpaceListNotifier {
  MockSpaceListNotifiers(this.spaces);

  final List<Space> spaces;

  @override
  List<Space> build() => spaces;
}
