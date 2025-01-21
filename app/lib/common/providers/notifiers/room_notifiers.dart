import 'dart:async';

import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Client, Room;
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::common::room_notifiers');

class AsyncMaybeRoomNotifier extends FamilyAsyncNotifier<Room?, String> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _poller;

  Future<Room?> _getRoom(Client client) async {
    try {
      return await client.room(arg);
    } catch (e) {
      _log.warning('room $arg not found', e);
      return null;
    }
  }

  @override
  Future<Room?> build(String arg) async {
    final client = await ref.watch(alwaysClientProvider.future);
    _listener = client.subscribeStream(arg); // keep it resident in memory
    _poller = _listener.listen(
      (data) async {
        _log.info('seen update for room $arg');
        state = await AsyncValue.guard(() async => await _getRoom(client));
      },
      onError: (e, s) {
        _log.severe('room stream errored', e, s);
      },
      onDone: () {
        _log.info('room stream ended');
      },
    );
    ref.onDispose(() => _poller.cancel());
    return await _getRoom(client);
  }
}

class RoomAvatarInfoNotifier extends FamilyNotifier<AvatarInfo, String> {
  late ProviderSubscription<AsyncValue<String?>> _displayNameListener;
  late ProviderSubscription<AsyncValue<MemoryImage?>> _avatarListener;

  @override
  AvatarInfo build(arg) {
    final roomId = arg;

    final fallback = AvatarInfo(uniqueId: roomId);

    final room = ref.watch(maybeRoomProvider(roomId)).valueOrNull;
    if (room == null) {
      return fallback;
    }

    final displayName = ref.read(roomDisplayNameProvider(roomId)).valueOrNull;
    final avatarData = ref.read(roomAvatarProvider(roomId)).valueOrNull;

    _avatarListener = ref.listen(
      roomAvatarProvider(roomId),
      (previous, next) => _maybeUpdate(roomId),
    );
    _displayNameListener = ref.listen(
      roomDisplayNameProvider(roomId),
      (previous, next) => _maybeUpdate(roomId),
    );

    ref.onDispose(() {
      _displayNameListener.close();
      _avatarListener.close();
    });

    return AvatarInfo(
      uniqueId: roomId,
      displayName: displayName,
      avatar: avatarData,
    );
  }

  void _maybeUpdate(String roomId) {
    final room = ref.watch(maybeRoomProvider(roomId)).valueOrNull;
    if (room == null) {
      // we do nothing, keep the old stuff as-is
      return;
    }

    bool updateDisplayName = false;
    bool updateAvatar = false;
    MemoryImage? newAvatar;
    String? newDisplayName;

    final displayName = ref.read(roomDisplayNameProvider(roomId));
    if (!displayName.isLoading &&
        !displayName.isRefreshing &&
        !displayName.isReloading) {
      // we ignore all cases of recomputing happening until they are done
      newDisplayName = displayName.valueOrNull;
      updateDisplayName = true;
    }

    final avatarData = ref.read(roomAvatarProvider(roomId));
    if (!avatarData.isLoading &&
        !avatarData.isReloading &&
        !avatarData.isRefreshing) {
      // we ignore all cases of recomputing happening until they are done
      newAvatar = avatarData.valueOrNull;
      updateAvatar = true;
    }

    if (updateAvatar || updateDisplayName) {
      // only update, if there was something interesting to update about;
      state = AvatarInfo(
        uniqueId: roomId,
        displayName: updateDisplayName ? newDisplayName : state.displayName,
        avatar: updateAvatar ? newAvatar : state.avatar,
      );
    }
  }
}
