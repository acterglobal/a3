import 'dart:async';

import 'package:acter/common/extensions/options.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::cross_signing::notifier');

class VerificationState {
  final String stage;
  final VerificationEvent? event; // null for verification.init

  const VerificationState({required this.stage, this.event});
}

class VerificationNotifier extends StateNotifier<VerificationState> {
  final Ref ref;
  final Client client;

  late Stream<OptionVerificationEvent>? _listener;
  late StreamSubscription<OptionVerificationEvent>? _poller;

  VerificationNotifier({
    required this.ref,
    required this.client,
  }) : super(const VerificationState(stage: 'verification.init')) {
    _init();
  }

  void _init() {
    _listener = client.verificationEventRx(); // keep it resident in memory
    _poller = _listener?.listen(
      (event) {
        final data = event.data();
        data.map(
          (event) => _handleEvent(event),
          orElse: () => _log.info('invalid verification event'),
        );
      },
      onError: (e, s) {
        _log.severe('stream errored', e, s);
      },
      onDone: () {
        _log.info('stream ended');
      },
    );
    ref.onDispose(() => _poller?.cancel());
  }

  void _handleEvent(VerificationEvent event) {
    String eventType = event.eventType();
    _log.info('$eventType - flow_id: ${event.flowId()}');
    switch (eventType) {
      /* request_verification_handler: verifier makes request */
      case 'VerificationRequestState::Created':
        state = VerificationState(stage: 'request.created', event: event);
        break;
      case 'VerificationRequestState::Requested':
        state = VerificationState(stage: 'request.requested', event: event);
        break;
      case 'VerificationRequestState::Ready':
        state = VerificationState(stage: 'request.ready', event: event);
        break;
      case 'VerificationRequestState::Transitioned': // after request accepted: available in verifiee too
        state = VerificationState(stage: 'request.transitioned', event: event);
        break;
      case 'VerificationRequestState::Done':
        state = VerificationState(stage: 'request.done', event: event);
        break;
      case 'VerificationRequestState::Cancelled':
        state = VerificationState(stage: 'request.cancelled', event: event);
        break;

      /* prior to sas */
      case 'm.key.verification.request':
        state = VerificationState(stage: 'verification.request', event: event);
        break;
      case 'm.key.verification.ready':
        state = VerificationState(stage: 'verification.ready', event: event);
        break;

      /* sas_verification_handler: after request accepted */
      case 'm.key.verification.start': // when start button was clicked by other
      case 'SasState::Started': // when start button was clicked by me
        state = VerificationState(stage: 'sas.started', event: event);
        break;
      case 'm.key.verification.cancel': // when verifier cancelled before verifiee accepts request
      case 'SasState::Cancelled':
        state = VerificationState(stage: 'sas.cancelled', event: event);
        break;
      // case 'm.key.verification.accept':
      case 'SasState::Accepted':
        state = VerificationState(stage: 'sas.accepted', event: event);
        break;
      // case 'm.key.verification.key':
      case 'SasState::KeysExchanged':
        state = VerificationState(stage: 'sas.keys_exchanged', event: event);
        break;
      // case 'm.key.verification.mac':
      case 'SasState::Confirmed':
        state = VerificationState(stage: 'sas.confirmed', event: event);
        break;
      // case 'm.key.verification.done':
      case 'SasState::Done':
        state = VerificationState(stage: 'sas.done', event: event);
        break;
    }
  }

  void finishFlow() {
    state = const VerificationState(stage: 'verification.init');
  }

  void launchFlow(VerificationEvent event) {
    state = VerificationState(stage: 'request.created', event: event);
  }
}
