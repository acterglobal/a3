import 'dart:async';

import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/features/chat_ui_showcase/models/mock_convo_list.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Client, Convo, ConvoDiff, TimelineItem;
import 'package:acter_notifify/util.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::common::chat_notifiers');

class AsyncConvoNotifier extends FamilyAsyncNotifier<Convo?, String> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _poller;

  @override
  FutureOr<Convo?> build(String arg) async {
    final roomId = arg;

    // if we are in chat showcase mode, return a mock convo
    if (includeChatShowcase && mockChatList.contains(arg)) {
      return mockConvoList.firstWhere((convo) => convo.getRoomIdStr() == arg);
    }

    // otherwise, get the convo from the client
    final client = await ref.watch(alwaysClientProvider.future);
    _listener = client.subscribeRoomStream(
      roomId,
    ); // keep it resident in memory
    _poller = _listener.listen(
      (data) async {
        state = await AsyncValue.guard(() async => await client.convo(roomId));
      },
      onError: (e, s) {
        _log.severe('convo stream errored', e, s);
        state = AsyncValue.error(e, s);
      },
      onDone: () {
        _log.info('convo stream ended');
      },
    );
    ref.onDispose(() => _poller.cancel());
    return await client.convoWithRetry(roomId, 120);
  }
}

class AsyncLatestMsgNotifier
    extends FamilyAsyncNotifier<TimelineItem?, String> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _poller;

  FutureOr<TimelineItem?> _refresh(String roomId) async {
    final convo = await ref.read(chatProvider(roomId).future);
    return convo?.latestMessage();
  }

  @override
  FutureOr<TimelineItem?> build(String arg) async {
    final roomId = arg;
    final client = await ref.watch(alwaysClientProvider.future);
    _listener = client.subscribeRoomParamStream(roomId, 'latest_message');
    _poller = _listener.listen(
      (data) async {
        _log.info('received new latest message call for $roomId');
        state = await AsyncValue.guard(() async => await _refresh(roomId));
      },
      onError: (e, s) {
        _log.severe('latest msg stream errored', e, s);
        state = AsyncValue.error(e, s);
      },
      onDone: () {
        _log.info('latest msg stream ended');
      },
    );
    ref.onDispose(() => _poller.cancel());
    return await _refresh(roomId);
  }
}

class ChatRoomsListNotifier extends Notifier<List<Convo>> {
  late Stream<ConvoDiff> _listener;
  StreamSubscription<ConvoDiff>? _poller;
  late ProviderSubscription _providerSubscription;

  void _reset(Client client) {
    state = List<Convo>.empty(growable: false);
    _listener = client.convosStream(); // keep it resident in memory
    _poller?.cancel();
    _poller = _listener.listen(
      _handleDiff,
      onError: (e, s) {
        _log.severe('convo list stream errored', e, s);
      },
      onDone: () {
        _log.info('convo list stream ended');
      },
    );
    ref.onDispose(() => _poller?.cancel());
  }

  List<Convo> listCopy() => List.from(state, growable: true);

  void _handleDiff(ConvoDiff diff) {
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

  @override
  List<Convo> build() {
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
    return List<Convo>.empty(growable: false);
  }
}

class SelectedChatIdNotifier extends Notifier<String?> {
  @override
  String? build() {
    return null;
  }

  void select(String? input) {
    input.map((roomId) => removeNotificationsForRoom(roomId));
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      state = input;
    });
  }
}
