import 'dart:async';

import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/util.dart';
import 'package:extension_nullable/extension_nullable.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::common::chat_notifiers');

class AsyncConvoNotifier extends FamilyAsyncNotifier<Convo?, String> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _poller;

  @override
  FutureOr<Convo?> build(String arg) async {
    final convoId = arg;
    final client = ref.watch(alwaysClientProvider);
    _listener = client.subscribeStream(convoId); // keep it resident in memory
    _poller = _listener.listen(
      (data) async {
        final newConvo = await client.convo(convoId);
        state = AsyncValue.data(newConvo);
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
    return await client.convoWithRetry(convoId, 120);
  }
}

class AsyncLatestMsgNotifier extends FamilyAsyncNotifier<RoomMessage?, String> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _poller;

  @override
  FutureOr<RoomMessage?> build(String arg) async {
    final roomId = arg;
    final client = ref.watch(alwaysClientProvider);
    _listener = client.subscribeStream('$roomId::latest_message');
    _poller = _listener.listen(
      (data) {
        _log.info('received new latest message call for $roomId');
        state = ref
            .watch(chatProvider(roomId))
            .whenData((cb) => cb?.latestMessage());
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
    return ref.watch(chatProvider(roomId)).valueOrNull?.latestMessage();
  }
}

class ChatRoomsListNotifier extends StateNotifier<List<Convo>> {
  final Client client;
  late Stream<ConvoDiff> _listener;
  late StreamSubscription<ConvoDiff> _poller;

  ChatRoomsListNotifier({
    required Ref ref,
    required this.client,
  }) : super(List<Convo>.empty(growable: false)) {
    _init(ref);
  }

  void _init(Ref ref) {
    _listener = client.convosStream(); // keep it resident in memory
    _poller = _listener.listen(
      _handleDiff,
      onError: (e, s) {
        _log.severe('convo list stream errored', e, s);
      },
      onDone: () {
        _log.info('convo list stream ended');
      },
    );
    ref.onDispose(() => _poller.cancel());
  }

  List<Convo> listCopy() => List.from(state, growable: true);

  void _handleDiff(ConvoDiff diff) {
    switch (diff.action()) {
      case 'Append':
        final newList = listCopy();
        List<Convo> items = diff.values()!.toList();
        newList.addAll(items);
        state = newList;
        break;
      case 'Insert':
        Convo m = diff.value()!;
        final index = diff.index()!;
        final newList = listCopy();
        newList.insert(index, m);
        state = newList;
        break;
      case 'Set':
        Convo m = diff.value()!;
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
        Convo m = diff.value()!;
        final newList = listCopy();
        newList.add(m);
        state = newList;
        break;
      case 'PushFront':
        Convo m = diff.value()!;
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

class SelectedChatIdNotifier extends Notifier<String?> {
  @override
  String? build() {
    return null;
  }

  void select(String? input) {
    input.map((p0) => removeNotificationsForRoom(p0));
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      state = input;
    });
  }
}
