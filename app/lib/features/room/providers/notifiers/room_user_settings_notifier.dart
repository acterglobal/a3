import 'dart:async';

import 'package:acter/common/providers/room_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show UserRoomSettings;
import 'package:riverpod/riverpod.dart';

class AsyncRoomUserSettingsNotifier
    extends AutoDisposeFamilyAsyncNotifier<UserRoomSettings, String> {
  late Stream<bool> _listener;

  Future<void> reload(String roomId) async {
    state = AsyncData(await fetch(roomId));
  }

  Future<UserRoomSettings> fetch(String roomId) async {
    final room = await ref.watch(maybeRoomProvider(roomId).future);
    if (room == null) {
      throw RoomNotFound();
    }
    return await room.userSettings();
  }

  @override
  Future<UserRoomSettings> build(String arg) async {
    final settings = await fetch(arg);
    _listener = settings.subscribeStream(); // keep it resident in memory
    _listener.forEach((e) async {
      reload(arg);
    });
    return settings;
  }
}
