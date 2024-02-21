import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';

// ignore_for_file: unused_field

class AsyncConvoNotifier extends FamilyAsyncNotifier<Convo?, Convo> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _sub;

  @override
  Future<Convo> build(Convo arg) async {
    final convo = arg;
    final convoId = convo.getRoomIdStr();
    final client = ref.watch(alwaysClientProvider);
    ref.onDispose(onDispose);
    _listener = client.subscribeStream(convoId);
    _sub = _listener.listen(
      (e) async {
        state = await AsyncValue.guard(() => client.convo(convoId));
      },
      onError: (e, stack) {
        debugPrint('stream errored: $e : $stack');
      },
      onDone: () {
        debugPrint('stream ended');
      },
    );
    return convo;
  }

  void onDispose() {
    debugPrint('disposing profile not for $arg');
    _sub.cancel();
  }
}

class LatestMsgNotifier extends StateNotifier<RoomMessage?> {
  final Ref ref;
  final Convo convo;
  late Stream<bool> _listener;
  late StreamSubscription<bool> _sub;

  LatestMsgNotifier(this.ref, this.convo) : super(null) {
    final convoId = convo.getRoomIdStr();
    state = convo.latestMessage();
    final client = ref.watch(alwaysClientProvider);
    _listener = client.subscribeStream('$convoId::latest_message');
    _sub = _listener.listen(
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
    ref.onDispose(onDispose);
  }

  void onDispose() {
    debugPrint('disposing latest msg listener for ${convo.getRoomIdStr()}');
    _sub.cancel();
  }
}

class ChatRoomsListNotifier extends StateNotifier<List<Convo>> {
  final Ref ref;
  final Client client;
  StreamSubscription<ConvoDiff>? subscription;

  ChatRoomsListNotifier({
    required this.ref,
    required this.client,
  }) : super(List<Convo>.empty(growable: false)) {
    _init();
  }

  void _init() async {
    subscription = client.convosStream().listen((diff) async {
      await _handleDiff(diff);
    });
    ref.onDispose(() async {
      debugPrint('disposing message stream');
      await subscription?.cancel();
    });
  }

  List<Convo> listCopy() => List.from(state, growable: true);

  Future<void> _handleDiff(ConvoDiff diff) async {
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
