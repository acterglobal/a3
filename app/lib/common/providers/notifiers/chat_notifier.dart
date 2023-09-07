import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:riverpod/riverpod.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ignore_for_file: unused_field

class AsyncConvoNotifier extends FamilyAsyncNotifier<Convo?, Convo> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _sub;

  @override
  Future<Convo> build(Convo arg) async {
    final convo = arg;
    final convoId = convo.getRoomId().toString();
    final client = ref.watch(clientProvider)!;
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
      default:
        break;
    }
  }
}
