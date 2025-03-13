// ignore_for_file: non_constant_identifier_names

import 'package:acter/common/providers/notifiers/room_notifiers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockRoom with Mock implements Room {}

class MockRoomUserSettings with Mock implements UserRoomSettings {
  final bool has_seen_suggested;
  final bool include_cal_sync;
  final Stream<bool>? stream;

  @override
  bool hasSeenSuggested() => has_seen_suggested;

  @override
  bool includeCalSync() => include_cal_sync;

  @override
  Stream<bool> subscribeStream() => stream ?? Stream.empty();

  MockRoomUserSettings({
    this.has_seen_suggested = false,
    this.include_cal_sync = true,
    this.stream,
  });
}

class MockAsyncMaybeRoomNotifier extends FamilyAsyncNotifier<Room?, String>
    with Mock
    implements AsyncMaybeRoomNotifier {
  final Map<String, Room> items;

  MockAsyncMaybeRoomNotifier({this.items = const {}});

  @override
  Future<Room?> build(arg) async => items[arg];
}

class MockAlwaysTheSameRoomNotifier extends FamilyAsyncNotifier<Room?, String>
    with Mock
    implements AsyncMaybeRoomNotifier {
  final Room? room;

  MockAlwaysTheSameRoomNotifier({this.room});

  @override
  Future<Room?> build(arg) async => room;
}

class MockRoomPreview with Mock implements RoomPreview {}

// Mock of RoomNotifier that returns a Room when requested.
class MockRoomNotifier extends Mock implements AsyncMaybeRoomNotifier {}

class MockRoomUserSettingsNotifier extends Mock
    implements MockRoomUserSettings {}

// Notifier to manage the state of the space's bookmarked status
class MockSpaceIsBookmarkedNotifier {
  final bool isBookmarked;

  MockSpaceIsBookmarkedNotifier(this.isBookmarked);

  // Simulate asynchronous behavior
  Future<bool> fetchBookmarkStatus() async {
    return isBookmarked;
  }
}
