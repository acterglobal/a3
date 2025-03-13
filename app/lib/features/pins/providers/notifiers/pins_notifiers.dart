import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show ActerPin, Client;
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::pins::pins_notifier');

//Get single pin details
class AsyncPinNotifier
    extends AutoDisposeFamilyAsyncNotifier<ActerPin, String> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _poller;

  Future<ActerPin> _getPin(Client client, String pinId) async {
    return await client.waitForPin(pinId, null);
  }

  @override
  Future<ActerPin> build(String arg) async {
    final pinId = arg;
    final client = await ref.watch(alwaysClientProvider.future);
    _listener = client.subscribeModelStream(
      pinId,
    ); // keep it resident in memory
    _poller = _listener.listen(
      (data) async {
        state = await AsyncValue.guard(
          () async => await _getPin(client, pinId),
        );
      },
      onError: (e, s) {
        _log.severe('stream errored', e, s);
      },
      onDone: () {
        _log.info('stream ended');
      },
    ); // stay up to date
    ref.onDispose(() => _poller.cancel());
    return await _getPin(client, pinId);
  }
}

//Get pin list details
class AsyncPinListNotifier
    extends FamilyAsyncNotifier<List<ActerPin>, String?> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _poller;

  @override
  Future<List<ActerPin>> build(String? arg) async {
    final spaceId = arg;
    final client = await ref.watch(alwaysClientProvider.future);

    //GET ALL PINS
    if (spaceId == null) {
      _listener = client.subscribeSectionStream('pins');
    } else {
      //GET SPACE PINS
      _listener = client.subscribeRoomSectionStream(spaceId, 'pins');
    }

    _poller = _listener.listen(
      (data) async {
        state = await AsyncValue.guard(
          () async => await _getPinList(client, spaceId),
        );
      },
      onError: (e, s) {
        _log.severe('stream errored', e, s);
      },
      onDone: () {
        _log.info('stream ended');
      },
    );
    ref.onDispose(() => _poller.cancel());
    return await _getPinList(client, spaceId);
  }

  Future<List<ActerPin>> _getPinList(Client client, String? spaceId) async {
    //GET ALL PINS
    if (spaceId == null) {
      return (await client.pins()).toList(); // this might throw internally
    } else {
      //GET SPACE PINS
      final space = await client.space(spaceId);
      return (await space.pins()).toList(); // this might throw internally
    }
  }
}
