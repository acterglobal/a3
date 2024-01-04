import 'dart:async';

import 'package:acter/features/cross_signing/models/cross_signing_state.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CrossSigningNotifier extends StateNotifier<CrossSigningState> {
  final Ref ref;
  final Client client;
  late StreamSubscription<VerificationEvent>? eventPoller;

  CrossSigningNotifier({
    required this.ref,
    required this.client,
  }) : super(const CrossSigningState.init()) {
    eventPoller = client.verificationEventRx()?.listen((event) {
      String eventType = event.eventType();
      debugPrint('$eventType - flow_id: ${event.flowId()}');
      switch (eventType) {
        case 'm.key.verification.request':
          state = CrossSigningState.request(event: event);
          break;
        case 'm.key.verification.ready':
          state = CrossSigningState.ready(event: event);
          break;
        case 'm.key.verification.start':
          state = CrossSigningState.start(event: event);
          break;
        case 'm.key.verification.cancel':
          state = CrossSigningState.cancel(event: event);
          break;
        case 'm.key.verification.accept':
          state = CrossSigningState.accept(event: event);
          break;
        case 'm.key.verification.key':
        case 'SasState::KeysExchanged':
          state = CrossSigningState.key(event: event);
          break;
        case 'm.key.verification.mac':
          state = CrossSigningState.mac(event: event);
          break;
        case 'm.key.verification.done':
          state = CrossSigningState.done(event: event);
          break;
      }
    });
  }

  @override
  void dispose() {
    eventPoller?.cancel();
    super.dispose();
  }

  void reset() {
    state = const CrossSigningState.init();
  }
}
