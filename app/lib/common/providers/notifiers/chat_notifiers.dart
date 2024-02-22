import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';

// ignore_for_file: unused_field

class AsyncConvoNotifier extends FamilyAsyncNotifier<Convo?, Convo> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _poller;

  @override
  FutureOr<Convo> build(Convo arg) async {
    final convo = arg;
    final convoId = convo.getRoomIdStr();
    final client = ref.watch(alwaysClientProvider);
    _listener = client.subscribeStream(convoId); // keep it resident in memory
    _poller = _listener.listen(
      (e) async {
        state = await AsyncValue.guard(() async => await client.convo(convoId));
      },
      onError: (e, stack) {
        debugPrint('stream errored: $e : $stack');
      },
      onDone: () {
        debugPrint('stream ended');
      },
    );
    ref.onDispose(() => _poller.cancel());
    return convo;
  }
}

class LatestMsgNotifier extends StateNotifier<RoomMessage?> {
  final Ref ref;
  final Convo convo;
  late Stream<bool> _listener;
  late StreamSubscription<bool> _poller;

  LatestMsgNotifier(this.ref, this.convo) : super(null) {
    final convoId = convo.getRoomIdStr();
    state = convo.latestMessage();
    final client = ref.watch(alwaysClientProvider);
    _listener = client.subscribeStream(
      '$convoId::latest_message',
    ); // keep it resident in memory
    _poller = _listener.listen(
      (e) {
        debugPrint('received new latest message call for $convoId');
        state = convo.latestMessage();
      },
      onError: (e, stack) {
        debugPrint('stream errored: $e : $stack');
      },
      onDone: () {
        debugPrint('stream ended');
      },
    );
    ref.onDispose(() => _poller.cancel());
  }
}

class ChatRoomsListNotifier extends StateNotifier<List<Convo>> {
  final Ref ref;
  final Client client;
  late Stream<ConvoDiff> _listener;
  late StreamSubscription<ConvoDiff> _poller;

  ChatRoomsListNotifier({
    required this.ref,
    required this.client,
  }) : super(List<Convo>.empty(growable: false)) {
    _init();
  }

  void _init() {
    _listener = client.convosStream(); // keep it resident in memory
    _poller = _listener.listen(_handleDiff);
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
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      state = input;
    });
  }
}
