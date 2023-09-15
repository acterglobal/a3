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
    OptionString displayName = await profile.getDisplayName();
    final avatar = await profile.getAvatar();
    return ProfileData(displayName.text(), avatar.data());
  }

  @override
  Future<ProfileData> build(Space arg) async {
    final client = ref.watch(clientProvider)!;
    ref.onDispose(onDispose);
    _listener = client.subscribeStream(arg.getRoomId().toString());
    _sub = _listener.listen(
      (e) async {
        debugPrint('seen update $arg');
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

class AsyncMaybeSpaceNotifier extends FamilyAsyncNotifier<Space?, String> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _sub;

  Future<Space?> _getSpace() async {
    final client = ref.read(clientProvider)!;
    return await client.space(arg);
  }

  @override
  Future<Space?> build(String arg) async {
    final client = ref.watch(clientProvider)!;
    ref.onDispose(onDispose);
    _listener = client.subscribeStream(arg);
    _sub = _listener.listen(
      (e) async {
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

class SpaceListNotifier extends StateNotifier<List<Space>> {
  final Ref ref;
  final Client client;
  StreamSubscription<SpaceDiff>? subscription;

  SpaceListNotifier({
    required this.ref,
    required this.client,
  }) : super(List<Space>.empty(growable: false)) {
    _init();
  }

  void _init() async {
    subscription = client.spacesStream().listen((diff) async {
      await _handleDiff(diff);
    });
    ref.onDispose(() async {
      debugPrint('disposing message stream');
      await subscription?.cancel();
    });
  }

  List<Space> listCopy() => List.from(state, growable: true);

  Future<void> _handleDiff(SpaceDiff diff) async {
    switch (diff.action()) {
      case 'Append':
        final newList = listCopy();
        List<Space> items = diff.values()!.toList();
        newList.addAll(items);
        state = newList;
        break;
      case 'Insert':
        Space m = diff.value()!;
        final index = diff.index()!;
        final newList = listCopy();
        newList.insert(index, m);
        state = newList;
        break;
      case 'Set':
        Space m = diff.value()!;
        final index = diff.index()!;
        final newList = listCopy();
        newList[index] = m;
        state = newList;
        break;
      case 'Remove':
        final index = diff.index()!;
        final newList = listCopy();
        newList.removeAt(index);
        state = newList;
        break;
      case 'PushBack':
        Space m = diff.value()!;
        final newList = listCopy();
        newList.add(m);
        state = newList;
        break;
      case 'PushFront':
        Space m = diff.value()!;
        final newList = listCopy();
        newList.insert(0, m);
        state = newList;
        break;
      case 'PopBack':
        final newList = listCopy();
        newList.removeLast();
        state = newList;
        break;
      case 'PopFront':
        final newList = listCopy();
        newList.removeAt(0);
        state = newList;
        break;
      case 'Clear':
        state = [];
        break;
      case 'Reset':
        state = diff.values()!.toList();
        break;
      default:
        break;
    }
  }
}
