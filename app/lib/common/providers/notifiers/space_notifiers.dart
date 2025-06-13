import 'dart:async';

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Client, Space, SpaceDiff;
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::common::space_notifiers');

class AsyncMaybeSpaceNotifier extends FamilyAsyncNotifier<Space?, String> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _poller;

  Future<Space?> _getSpace(Client client) async {
    return await client.space(arg);
  }

  @override
  Future<Space?> build(String arg) async {
    final client = await ref.watch(alwaysClientProvider.future);
    _listener = client.subscribeRoomStream(arg); // keep it resident in memory
    _poller = _listener.listen(
      (data) async {
        _log.info('seen update $arg');
        state = AsyncValue.data(await _getSpace(client));
      },
      onError: (e, s) {
        _log.severe('space stream errored', e, s);
      },
      onDone: () {
        _log.info('space stream ended');
      },
    );
    ref.onDispose(() => _poller.cancel());
    return await _getSpace(client);
  }
}

class SpaceListNotifier extends Notifier<List<Space>> {
  late Stream<SpaceDiff> _listener;
  StreamSubscription<SpaceDiff>? _poller;
  late ProviderSubscription _providerSubscription;

  @override
  List<Space> build() {
    _providerSubscription = ref.listen<AsyncValue<Client?>>(
      alwaysClientProvider,
      (AsyncValue<Client?>? oldVal, AsyncValue<Client?> newVal) {
        final client = newVal.valueOrNull;
        if (client == null) {
          // we don't care for not having a proper client yet
          return;
        }
        _reset(client);
      },
      fireImmediately: true,
    );
    ref.onDispose(() => _providerSubscription.close());
    return List<Space>.empty(growable: false);
  }

  void _reset(Client client) async {
    _listener = client.spacesStream(); // keep it resident in memory
    _poller?.cancel();
    state = List<Space>.empty(growable: false);
    _poller = _listener.listen(
      _handleDiff,
      onError: (e, s) {
        _log.severe('space list stream errored', e, s);
      },
      onDone: () {
        _log.info('space list stream ended');
      },
    );
    ref.onDispose(() => _poller?.cancel());
  }

  List<Space> listCopy() => List.from(state, growable: true);

  void _handleDiff(SpaceDiff diff) {
    switch (diff.action()) {
      case 'Append':
        final values = diff.values();
        if (values == null) {
          _log.severe('On append action, values should be available');
          return;
        }
        final newList = listCopy();
        newList.addAll(values.toList());
        state = newList;
        break;
      case 'Insert':
        final value = diff.value();
        if (value == null) {
          _log.severe('On insert action, value should be available');
          return;
        }
        final index = diff.index();
        if (index == null) {
          _log.severe('On insert action, index should be available');
          return;
        }
        final newList = listCopy();
        newList.insert(index, value);
        state = newList;
        break;
      case 'Set':
        final value = diff.value();
        if (value == null) {
          _log.severe('On set action, value should be available');
          return;
        }
        final index = diff.index();
        if (index == null) {
          _log.severe('On set action, index should be available');
          return;
        }
        final newList = listCopy();
        newList[index] = value;
        state = newList;
        break;
      case 'Remove':
        final index = diff.index();
        if (index == null) {
          _log.severe('On remove action, index should be available');
          return;
        }
        final newList = listCopy();
        newList.removeAt(index);
        state = newList;
        break;
      case 'PushBack':
        final value = diff.value();
        if (value == null) {
          _log.severe('On push back action, value should be available');
          return;
        }
        final newList = listCopy();
        newList.add(value);
        state = newList;
        break;
      case 'PushFront':
        final value = diff.value();
        if (value == null) {
          _log.severe('On push front action, value should be available');
          return;
        }
        final newList = listCopy();
        newList.insert(0, value);
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
        final values = diff.values();
        if (values == null) {
          _log.severe('On reset action, values should be available');
          return;
        }
        state = values.toList();
        break;
      case 'Truncate':
        final index = diff.index();
        if (index == null) {
          _log.severe('On truncate action, index should be available');
          return;
        }
        final newList = listCopy();
        state = newList.take(index).toList();
        break;
      default:
        break;
    }
  }
}

class SpaceBookmarkNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() {
    final spaces = ref.watch(spacesProvider);
    return Map.fromEntries(
      spaces.map((space) => MapEntry(
        space.getRoomIdStr(),
        space.isBookmarked(),
      )),
    );
  }

  Future<void> setBookmark(String spaceId) async {
    final space = await ref.read(spaceProvider(spaceId).future);
    final newValue = !(state[spaceId] ?? false);
    await space.setBookmarked(newValue);
    state = {...state, spaceId: newValue};
  }

  bool getBookmark(String spaceId) => state[spaceId] ?? false;
}