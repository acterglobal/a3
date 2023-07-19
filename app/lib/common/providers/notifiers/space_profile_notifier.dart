import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:riverpod/riverpod.dart';
import 'package:acter/common/models/profile_data.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/foundation.dart';

// ignore_for_file: unused_field

class AsyncSpaceProfileDataNotifier
    extends FamilyAsyncNotifier<ProfileData, Space> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _sub;
  Future<ProfileData> _getSpaceProfileData() async {
    final space = arg;
    final profile = space.getProfile();
    OptionText displayName = await profile.getDisplayName();
    final avatar = await profile.getAvatar();
    return ProfileData(displayName.text(), avatar.data());
  }

  @override
  Future<ProfileData> build(Space arg) async {
    final client = ref.watch(clientProvider)!;
    ref.onDispose(onDispose);
    _listener = client.subscribeStream(arg.getRoomId().toString());
    _sub = _listener.listen(
      (_e) async {
        debugPrint('seen update ${arg.getRoomIdStr()}');
        state = await AsyncValue.guard(() => _getSpaceProfileData());
      },
      onError: (e, stack) {
        debugPrint('stream errored: $e : $stack');
      },
      onDone: () {
        debugPrint('stream ended');
      },
    );
    return _getSpaceProfileData();
  }

  void onDispose() {
    debugPrint('disposing profile not for $arg');
    _sub.cancel();
  }
}

class AsyncSpaceNotifier extends FamilyAsyncNotifier<Space, String> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _sub;
  Future<Space> _getSpace() async {
    final client = ref.watch(clientProvider)!;
    return await client.getSpace(arg); // this might throw internally
  }

  @override
  Future<Space> build(String arg) async {
    final client = ref.watch(clientProvider)!;
    ref.onDispose(onDispose);
    _listener = client.subscribeStream(arg);
    _sub = _listener.listen(
      (_e) async {
        debugPrint('Received space update $arg');
        state = await AsyncValue.guard(() => _getSpace());
      },
      onError: (e, stack) {
        debugPrint('stream errored: $e : $stack');
      },
      onDone: () {
        debugPrint('stream ended');
      },
    );
    return _getSpace();
  }

  void onDispose() {
    debugPrint('disposing profile not for $arg');
    _sub.cancel();
  }
}

class AsyncMaybeSpaceNotifier extends FamilyAsyncNotifier<Space?, String> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _sub;
  Future<Space?> _getSpace() async {
    final client = ref.watch(clientProvider)!;
    try {
      return await client.getSpace(arg);
    } catch (e) {
      // we sneakly suggest that means we don't have access.
      return null;
    }
  }

  @override
  Future<Space?> build(String arg) async {
    final client = ref.watch(clientProvider)!;
    ref.onDispose(onDispose);
    _listener = client.subscribeStream(arg);
    _sub = _listener.listen(
      (_e) async {
        debugPrint('seen update $arg');
        state = await AsyncValue.guard(() => _getSpace());
      },
      onError: (e, stack) {
        debugPrint('stream errored: $e : $stack');
      },
      onDone: () {
        debugPrint('stream ended');
      },
    );
    return _getSpace();
  }

  void onDispose() {
    debugPrint('disposing profile not for $arg');
    _sub.cancel();
  }
}

class AsyncSpacesNotifier extends AsyncNotifier<List<Space>> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _sub;

  Future<List<Space>> _getSpaces() async {
    final client = ref.watch(clientProvider)!;
    final spaces = await client.spaces();
    return spaces.toList(); // this might throw internally
  }

  @override
  Future<List<Space>> build() async {
    final client = ref.watch(clientProvider)!;
    ref.onDispose(onDispose);
    _listener = client.subscribeStream('SPACES');
    _sub = _listener.listen(
      (_e) async {
        debugPrint('seen update on SPACES');
        state = await AsyncValue.guard(() => _getSpaces());
      },
      onError: (e, stack) {
        debugPrint('stream errored: $e : $stack');
      },
      onDone: () {
        debugPrint('stream ended');
      },
    );
    return _getSpaces();
  }

  void onDispose() {
    debugPrint('disposing profile for SPACES');
    _sub.cancel();
  }
}
