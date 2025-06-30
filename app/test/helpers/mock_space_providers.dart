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
  bool shouldFail;

  RetryMockAsyncSpaceNotifier({this.mockSpace, this.shouldFail = true});

  final Space? mockSpace;

  @override
  Future<Space> build(String arg) async {
    if (shouldFail) {
      // toggle failure so the retry works
      shouldFail = !shouldFail;
      throw 'Expected fail: Space not loaded';
    }
    return mockSpace ?? MockSpace();
  }
}

class MaybeMockAsyncSpaceNotifier extends FamilyAsyncNotifier<Space?, String>
    with Mock
    implements AsyncMaybeSpaceNotifier {
  final Space? mockSpace;
  MaybeMockAsyncSpaceNotifier({this.mockSpace});

  @override
  Future<Space?> build(String arg) async => mockSpace;
}

class MockSpace extends Mock implements Space {
  final String id;
  final bool bookmarked;
  final bool _isJoined;

  MockSpace({this.id = 'id', this.bookmarked = false, isJoined = true})
    : _isJoined = isJoined;

  @override
  String getRoomIdStr() => id;

  @override
  bool isBookmarked() => bookmarked;

  @override
  bool isJoined() => _isJoined;
}

class MockFfiListString extends Fake implements FfiListFfiString {
  final List<String> items;

  MockFfiListString({this.items = const []});

  List<String> toDart() => items;

  @override
  bool get isEmpty => items.isEmpty;
}

class MockSpaceHierarchyRoomInfo extends Fake
    implements SpaceHierarchyRoomInfo {
  final String roomId;
  final String? roomName;
  final String joinRule;
  final List<String> serverNames;
  final bool isSuggested;

  MockSpaceHierarchyRoomInfo({
    required this.roomId,
    this.roomName,
    this.joinRule = 'Private',
    this.isSuggested = false,
    this.serverNames = const [],
  });

  @override
  String roomIdStr() => roomId;

  @override
  String? name() => roomName;

  @override
  String joinRuleStr() => joinRule;

  @override
  MockFfiListString viaServerNames() => MockFfiListString(items: serverNames);

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
