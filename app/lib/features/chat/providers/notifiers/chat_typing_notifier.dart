import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show TypingEvent;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatTypingEventNotifier extends Notifier<TypingEvent?> {
  StreamSubscription? _subscription;
  @override
  TypingEvent? build() {
    final client = ref.watch(alwaysClientProvider);
    final typingStream = client.typingEventRx();
    if (typingStream != null) {
      _subscription = typingStream.listen((t) {
        state = t;
      });
    }
    ref.onDispose(() => dispose());
    return state;
  }

  // restart the stream
  void restart() {
    if (_subscription == null) {
      build();
    }
  }

  // disposes the stream
  void dispose() {
    _subscription?.cancel();
  }
}
