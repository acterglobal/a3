import 'dart:async';

import 'package:acter/common/models/profile_data.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::common::space');

class AsyncSpaceProfileDataNotifier
    extends FamilyAsyncNotifier<ProfileData, Space> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _poller;

  Future<ProfileData> _getSpaceProfileData() async {
    final space = arg;
    final profile = space.getProfile();
    OptionString displayName = await profile.getDisplayName();
    final sdk = await ref.read(sdkProvider.future);
    final size = sdk.api.newThumbSize(48, 48);
    final avatar = await profile.getAvatar(size);
    return ProfileData(displayName.text(), avatar.data());
  }

  @override
  Future<ProfileData> build(Space arg) async {
    final client = ref.watch(alwaysClientProvider);
    _listener = client
        .subscribeStream(arg.getRoomIdStr()); // keep it resident in memory
    _poller = _listener.listen(
      (e) async {
        _log.info('seen update $arg');
        state = await AsyncValue.guard(_getSpaceProfileData);
      },
      onError: (e, stack) {
        _log.severe('stream errored', e, stack);
      },
      onDone: () {
        _log.info('stream ended');
      },
    );
    ref.onDispose(() => _poller.cancel());
    return await _getSpaceProfileData();
  }
}

class AsyncMaybeSpaceNotifier extends FamilyAsyncNotifier<Space?, String> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _poller;

  Future<Space?> _getSpace() async {
    final client = ref.read(alwaysClientProvider);
    return await client.space(arg);
  }

  @override
  Future<Space?> build(String arg) async {
    final client = ref.watch(alwaysClientProvider);
    _listener = client.subscribeStream(arg); // keep it resident in memory
    _poller = _listener.listen(
      (e) async {
        _log.info('seen update $arg');
        state = await AsyncValue.guard(_getSpace);
      },
      onError: (e, stack) {
        _log.severe('stream errored', e, stack);
      },
      onDone: () {
        _log.info('stream ended');
      },
    );
    ref.onDispose(() => _poller.cancel());
    return await _getSpace();
  }
}

class SpaceListNotifier extends StateNotifier<List<Space>> {
  final Ref ref;
  final Client client;
  late Stream<SpaceDiff> _listener;
  late StreamSubscription<SpaceDiff> _poller;

  SpaceListNotifier({
    required this.ref,
    required this.client,
  }) : super(List<Space>.empty(growable: false)) {
    _init();
  }

  void _init() async {
    _listener = client.spacesStream(); // keep it resident in memory
    _poller = _listener.listen(_handleDiff);
    ref.onDispose(() => _poller.cancel());
  }

  List<Space> listCopy() => List.from(state, growable: true);

  void _handleDiff(SpaceDiff diff) {
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
      case 'Truncate':
        final length = diff.index()!;
        final newList = listCopy();
        state = newList.take(length).toList();
        break;
      default:
        break;
    }
  }
}
