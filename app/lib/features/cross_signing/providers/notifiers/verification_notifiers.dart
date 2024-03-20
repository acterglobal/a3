import 'dart:async';

import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::cross_signing::notifier');

class VerificationState {
  final String stage;
  final VerificationEvent? event; // null for verification.init
  final bool isVerifier; // whether this device requested verification
  final String? flowId; // if not null, verification flying now
  final bool keysExchanged;

  const VerificationState({
    required this.stage,
    this.event,
    required this.isVerifier,
    this.flowId,
    required this.keysExchanged,
  });

  @override
  bool operator ==(Object other) {
    if (other is! VerificationState) {
      _log.info('is not VerificationState');
      return false;
    }
    if (other.stage != stage) {
      _log.info('stage is not same');
      return false;
    }
    // don't compare isVerifier & flowId & keysExchanged
    // because they are changed via changeState in ref.listen
    return true;
  }

  @override
  int get hashCode => stage.hashCode;
}

class VerificationNotifier extends StateNotifier<VerificationState> {
  final Ref ref;
  final Client client;

  late Stream<VerificationEvent>? _listener;
  late StreamSubscription<VerificationEvent>? _poller;

  VerificationNotifier({
    required this.ref,
    required this.client,
  }) : super(
          const VerificationState(
            stage: 'verification.init',
            isVerifier: false,
            keysExchanged: false,
          ),
        ) {
    _init();
  }

  void _init() {
    _listener = client.verificationEventRx(); // keep it resident in memory
    _poller = _listener?.listen(_handleEvent);
    ref.onDispose(() => _poller?.cancel());
  }

  void _handleEvent(VerificationEvent event) {
    String eventType = event.eventType();
    _log.info('$eventType - flow_id: ${event.flowId()}');
    switch (eventType) {
      /* request_verification_handler: verifier makes request */
      case 'VerificationRequestState::Created':
        state = VerificationState(
          stage: 'request.created',
          event: event,
          isVerifier: state.isVerifier,
          flowId: state.flowId,
          keysExchanged: state.keysExchanged,
        );
        break;
      case 'VerificationRequestState::Requested':
        state = VerificationState(
          stage: 'request.requested',
          event: event,
          isVerifier: state.isVerifier,
          flowId: state.flowId,
          keysExchanged: state.keysExchanged,
        );
        break;
      case 'VerificationRequestState::Ready':
        state = VerificationState(
          stage: 'request.ready',
          event: event,
          isVerifier: state.isVerifier,
          flowId: state.flowId,
          keysExchanged: state.keysExchanged,
        );
        break;
      case 'VerificationRequestState::Transitioned': // after request accepted: available in verifiee too
        state = VerificationState(
          stage: 'request.transitioned',
          event: event,
          isVerifier: state.isVerifier,
          flowId: state.flowId,
          keysExchanged: state.keysExchanged,
        );
        break;
      case 'VerificationRequestState::Done':
        state = VerificationState(
          stage: 'request.done',
          event: event,
          isVerifier: state.isVerifier,
          flowId: state.flowId,
          keysExchanged: state.keysExchanged,
        );
        break;
      case 'VerificationRequestState::Cancelled':
        state = VerificationState(
          stage: 'request.cancelled',
          event: event,
          isVerifier: state.isVerifier,
          flowId: state.flowId,
          keysExchanged: state.keysExchanged,
        );
        break;

      /* prior to sas */
      case 'm.key.verification.request':
        state = VerificationState(
          stage: 'verification.request',
          event: event,
          isVerifier: state.isVerifier,
          flowId: state.flowId,
          keysExchanged: state.keysExchanged,
        );
        break;
      case 'm.key.verification.ready':
        state = VerificationState(
          stage: 'verification.ready',
          event: event,
          isVerifier: state.isVerifier,
          flowId: state.flowId,
          keysExchanged: state.keysExchanged,
        );
        break;

      /* sas_verification_handler: after request accepted */
      case 'm.key.verification.start': // when start button was clicked by other
      case 'SasState::Started': // when start button was clicked by me
        state = VerificationState(
          stage: 'sas.started',
          event: event,
          isVerifier: state.isVerifier,
          flowId: state.flowId,
          keysExchanged: state.keysExchanged,
        );
        break;
      case 'm.key.verification.cancel': // when verifier cancelled before verifiee accepts request
      case 'SasState::Cancelled':
        state = VerificationState(
          stage: 'sas.cancelled',
          event: event,
          isVerifier: state.isVerifier,
          flowId: state.flowId,
          keysExchanged: state.keysExchanged,
        );
        break;
      // case 'm.key.verification.accept':
      case 'SasState::Accepted':
        state = VerificationState(
          stage: 'sas.accepted',
          event: event,
          isVerifier: state.isVerifier,
          flowId: state.flowId,
          keysExchanged: state.keysExchanged,
        );
        break;
      // case 'm.key.verification.key':
      case 'SasState::KeysExchanged':
        state = VerificationState(
          stage: 'sas.keys_exchanged',
          event: event,
          isVerifier: state.isVerifier,
          flowId: state.flowId,
          keysExchanged: state.keysExchanged,
        );
        break;
      // case 'm.key.verification.mac':
      case 'SasState::Confirmed':
        state = VerificationState(
          stage: 'sas.confirmed',
          event: event,
          isVerifier: state.isVerifier,
          flowId: state.flowId,
          keysExchanged: state.keysExchanged,
        );
        break;
      // case 'm.key.verification.done':
      case 'SasState::Done':
        state = VerificationState(
          stage: 'sas.done',
          event: event,
          isVerifier: state.isVerifier,
          flowId: state.flowId,
          keysExchanged: state.keysExchanged,
        );
        break;
    }
  }

  void finishFlow() {
    state = const VerificationState(
      stage: 'verification.init',
      isVerifier: false,
      keysExchanged: false,
    );
  }

  void launchFlow(VerificationEvent event) {
    state = VerificationState(
      stage: 'request.created',
      event: event,
      isVerifier: false,
      keysExchanged: false,
    );
  }

  void changeState({bool? isVerifier, String? flowId, bool? keysExchanged}) {
    state = VerificationState(
      stage: state.stage,
      event: state.event,
      isVerifier: isVerifier ?? state.isVerifier,
      flowId: flowId ?? state.flowId,
      keysExchanged: keysExchanged ?? state.keysExchanged,
    );
  }
}
