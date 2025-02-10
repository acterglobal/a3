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

class MockMaybeRoomNotifier extends FamilyNotifier<Room?, String>
    with Mock
    implements MaybeRoomNotifier {
  final Map<String, Room> items;

  MockMaybeRoomNotifier({this.items = const {}});

  @override
  Room? build(arg) => items[arg];
}

class MockAlwaysTheSameRoomNotifier extends FamilyNotifier<Room?, String>
    with Mock
    implements MaybeRoomNotifier {
  final Room? room;

  MockAlwaysTheSameRoomNotifier({this.room});

  @override
  Room? build(arg) => room;
}

class MockRoomPreview with Mock implements RoomPreview {}
