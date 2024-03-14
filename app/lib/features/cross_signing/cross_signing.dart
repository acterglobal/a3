import 'dart:async';

import 'package:acter/features/cross_signing/pages/request_cancelled.dart';
import 'package:acter/features/cross_signing/pages/request_created.dart';
import 'package:acter/features/cross_signing/pages/request_ready.dart';
import 'package:acter/features/cross_signing/pages/sas_accepted.dart';
import 'package:acter/features/cross_signing/pages/sas_cancelled.dart';
import 'package:acter/features/cross_signing/pages/sas_done.dart';
import 'package:acter/features/cross_signing/pages/sas_keys_exchanged.dart';
import 'package:acter/features/cross_signing/pages/sas_started.dart';
import 'package:acter/features/cross_signing/pages/verification_request.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:events_emitter/events_emitter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::cross_signing');

class CrossSigning {
  final Client client;
  final Ref ref;

  final EventEmitter _verifEmitter = EventEmitter();
  bool _isVerifier = false; // whether this device requested verification
  String? _flowId; // if not null, verification flying now
  Stream<VerificationEvent>? _verifListener;
  StreamSubscription<VerificationEvent>? _verifPoller;

  CrossSigning(this.client, this.ref) {
    _verifListener = client.verificationEventRx(); // keep it resident in memory
    _verifPoller = _verifListener?.listen((event) {
      String eventType = event.eventType();
      _log.info('$eventType - flow_id: ${event.flowId()}');
      switch (eventType) {
        /* request_verification_handler: verifier makes request */
        case 'VerificationRequestState::Created':
          _verifEmitter.emit('request.created', event);
          break;
        case 'VerificationRequestState::Requested':
          _verifEmitter.emit('request.requested', event);
          break;
        case 'VerificationRequestState::Ready':
          _verifEmitter.emit('request.ready', event);
          break;
        case 'VerificationRequestState::Transitioned': // after request accepted: available in verifiee too
          _verifEmitter.emit('request.transitioned', event);
          break;
        case 'VerificationRequestState::Done':
          _verifEmitter.emit('request.done', event);
          break;
        case 'VerificationRequestState::Cancelled':
          _verifEmitter.emit('request.cancelled', event);
          break;

        /* prior to sas */
        case 'm.key.verification.request':
          _verifEmitter.emit('verification.request', event);
          break;
        case 'm.key.verification.ready':
          _verifEmitter.emit('verification.ready', event);
          break;

        /* sas_verification_handler: after request accepted */
        case 'm.key.verification.start': // when start button was clicked by other
        case 'SasState::Started': // when start button was clicked by me
          _verifEmitter.emit('sas.started', event);
          break;
        case 'm.key.verification.cancel': // when verifier cancelled before verifiee accepts request
        case 'SasState::Cancelled':
          _verifEmitter.emit('sas.cancelled', event);
          break;
        // case 'm.key.verification.accept':
        case 'SasState::Accepted':
          _verifEmitter.emit('sas.accepted', event);
          break;
        // case 'm.key.verification.key':
        case 'SasState::KeysExchanged':
          _verifEmitter.emit('sas.keys_exchanged', event);
          break;
        // case 'm.key.verification.mac':
        case 'SasState::Confirmed':
          _verifEmitter.emit('sas.confirmed', event);
          break;
        // case 'm.key.verification.done':
        case 'SasState::Done':
          _verifEmitter.emit('sas.done', event);
          break;
      }
    });
    ref.onDispose(() => _verifPoller?.cancel());
  }

  void installEventFilter(BuildContext context) {
    _verifEmitter.on('verification.init', (_) {
      onVerificationInit(context);
    });

    _verifEmitter.on<VerificationEvent>('request.created', (event) {
      if (context.mounted) onRequestCreated(context, event);
    });
    _verifEmitter.on<VerificationEvent>('request.requested', (event) {
      if (context.mounted) onRequestRequested(context, event);
    });
    _verifEmitter.on<VerificationEvent>('request.ready', (event) {
      if (context.mounted) onRequestReady(context, event);
    });
    _verifEmitter.on<VerificationEvent>('request.transitioned', (event) {
      if (context.mounted) onRequestTransitioned(context, event);
    });
    _verifEmitter.on<VerificationEvent>('request.done', (event) {
      if (context.mounted) onRequestDone(context, event);
    });
    _verifEmitter.on<VerificationEvent>('request.cancelled', (event) {
      if (context.mounted) onRequestCancelled(context, event);
    });

    _verifEmitter.on<VerificationEvent>('verification.request', (event) {
      if (context.mounted) onVerificationRequest(context, event);
    });
    _verifEmitter.on<VerificationEvent>('verification.ready', (event) {
      if (context.mounted) onVerificationReady(context, event);
    });

    _verifEmitter.on<VerificationEvent>('sas.started', (event) {
      if (context.mounted) onSasStarted(context, event);
    });
    _verifEmitter.on<VerificationEvent>('sas.accepted', (event) {
      if (context.mounted) onSasAccepted(context, event);
    });
    _verifEmitter.on<VerificationEvent>('sas.cancelled', (event) {
      if (context.mounted) onSasCancelled(context, event);
    });
    _verifEmitter.on<VerificationEvent>('sas.keys_exchanged', (event) {
      if (context.mounted) onSasKeysExchanged(context, event);
    });
    _verifEmitter.on<VerificationEvent>('sas.confirmed', (event) {
      if (context.mounted) onSasConfirmed(context, event);
    });
    _verifEmitter.on<VerificationEvent>('sas.done', (event) {
      if (context.mounted) onSasDone(context, event);
    });
  }

  void removeEventFilter() {
    _verifEmitter.off(type: 'verification.init');

    _verifEmitter.off(type: 'request.created');
    _verifEmitter.off(type: 'request.requested');
    _verifEmitter.off(type: 'request.ready');
    _verifEmitter.off(type: 'request.transitioned');
    _verifEmitter.off(type: 'request.done');
    _verifEmitter.off(type: 'request.cancelled');

    _verifEmitter.off(type: 'verification.request');
    _verifEmitter.off(type: 'verification.ready');

    _verifEmitter.off(type: 'sas.started');
    _verifEmitter.off(type: 'sas.accepted');
    _verifEmitter.off(type: 'sas.cancelled');
    _verifEmitter.off(type: 'sas.keys_exchanged');
    _verifEmitter.off(type: 'sas.confirmed');
    _verifEmitter.off(type: 'sas.done');
  }

  void onVerificationInit(BuildContext context) {
    _log.info('emitter verification.init');

    // close dialog from previous stage, ex: sas.done
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();
  }

  // verifier
  void onRequestCreated(BuildContext context, VerificationEvent event) {
    _log.info('emitter request.created');

    // starting of active verification
    final flowId = event.flowId();
    _flowId = flowId;
    _isVerifier = true;

    // open request.created dialog
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => RequestCreatedPage(
        onCancel: (BuildContext context) async {
          // cancel verification request launched by this device
          await event.cancelVerificationRequest();
        },
      ),
      isDismissible: false,
    );
  }

  // verifier
  void onRequestRequested(BuildContext context, VerificationEvent event) {
    _log.info('emitter request.requested');
  }

  // both of verifier & verifiee
  void onRequestReady(BuildContext context, VerificationEvent event) {
    _log.info('emitter request.ready');

    // close dialog from previous stage, ex: verification.request
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();

    // open request.ready dialog
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => RequestReadyPage(
        isVerifier: _isVerifier,
        onCancel: (BuildContext context) async {
          await event.cancelVerificationRequest(); // occurs request.cancelled
        },
        onAccept: (BuildContext context) async {
          // start sas verification from this device
          await event.startSasVerification(); // occurs request.transitioned
        },
      ),
      isDismissible: false,
    );
  }

  void onRequestTransitioned(BuildContext context, VerificationEvent event) {
    _log.info('emitter request.transitioned');

    // start sas event loop
    client.installSasEventHandler(event.flowId());
  }

  void onRequestDone(BuildContext context, VerificationEvent event) {
    _log.info('emitter request.done');
    if (_flowId == null) {
      return; // already finished due to sas.done happened just before
    }
    _flowId = null;
  }

  // both of verifier & verifiee get this event when verification was cancelled before start
  void onRequestCancelled(BuildContext context, VerificationEvent event) {
    _log.info('emitter request.cancelled');
    if (_flowId == null) {
      return; // already finished due to sas.cancelled happened just before
    }
    _flowId = null;

    // close dialog from previous stage, ex: request.transitioned
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();

    // [ref] https://spec.matrix.org/unstable/client-server-api/#mkeyverificationcancel
    var reason = event.getContent('reason');
    if (reason == 'Unknown cancel reason') {
      reason = null;
    }
    // open request.cancel dialog
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => RequestCancelledPage(
        sender: event.sender(),
        isVerifier: _isVerifier,
        message: reason,
        onDone: (BuildContext context) => emitEvent('verification.init'),
      ),
      isDismissible: false,
    );
  }

  void onVerificationRequest(BuildContext context, VerificationEvent event) {
    _log.info('emitter verification.request');

    // starting of verifiee's flow
    final flowId = event.flowId();
    _flowId = flowId;
    _isVerifier = false;

    // start request event loop
    client.installRequestEventHandler(flowId);

    // open verification.request dialog
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => VerificationRequestPage(
        sender: event.sender(),
        onCancel: (BuildContext context) async {
          // cancel verification request from other device
          await event.cancelVerificationRequest();
        },
        onAccept: (BuildContext context) async {
          // accept verification request from other device
          await event.acceptVerificationRequest();
        },
      ),
      isDismissible: false,
    );
  }

  void onVerificationReady(BuildContext context, VerificationEvent event) {
    _log.info('emitter verification.ready');
  }

  // verifiee gets this event when verifier clicked start
  void onSasStarted(BuildContext context, VerificationEvent event) {
    _log.info('emitter sas.started');

    // close dialog from previous stage, ex: request.transitioned
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();

    // accept sas that verifier started
    event.acceptSasVerification();

    // open sas.started dialog
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => SasStartedPage(
        isVerifier: _isVerifier,
        onCancel: (BuildContext context) async {
          await event.cancelSasVerification();
        },
      ),
      isDismissible: false,
    );
  }

  // verifiee gets this event when verifiee clicked start
  void onSasAccepted(BuildContext context, VerificationEvent event) {
    _log.info('emitter sas.accepted');

    // close dialog from previous stage, ex: request.transitioned
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();

    // open sas.accept dialog
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => SasAcceptedPage(
        sender: event.sender(),
        isVerifier: _isVerifier,
      ),
      isDismissible: false,
    );
  }

  // both of verifier & verifiee get this event when verification was cancelled after start
  void onSasCancelled(BuildContext context, VerificationEvent event) {
    _log.info('emitter sas.cancelled');
    if (_flowId == null) {
      return; // already finished due to request.cancelled happened just before
    }
    _flowId = null;

    // close dialog from previous stage, ex: sas.keys_exchanged
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();

    // [ref] https://spec.matrix.org/unstable/client-server-api/#mkeyverificationcancel
    var reason = event.getContent('reason');
    if (reason == 'Unknown cancel reason') {
      reason = null;
    }
    // open sas.cancelled dialog
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => SasCancelledPage(
        sender: event.sender(),
        isVerifier: _isVerifier,
        message: reason,
        onDone: (BuildContext context) => emitEvent('verification.init'),
      ),
      isDismissible: false,
    );
  }

  void onSasKeysExchanged(BuildContext context, VerificationEvent event) {
    _log.info('emitter sas.keys_exchanged');

    // close dialog from previous stage, ex: sas.started
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();

    if (_isVerifier) {
      // open sas.keys_exchanged dialog
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) => SasKeysExchangedPage(
          sender: event.sender(),
          isVerifier: _isVerifier,
          emojis: event.emojis(),
          onCancel: (BuildContext context) async {
            await event.cancelSasVerification();
          },
          onMatch: (BuildContext context) async {
            _log.info('sas.keys_exchanged - match');
            await event.confirmSasVerification();
          },
          onMismatch: (BuildContext context) async {
            _log.info('sas.keys_exchanged - mismatch');
            await event.mismatchSasVerification();
          },
        ),
        isDismissible: false,
      );
    } else {
      // fetch emojis
      event.getEmojis().then((emojis) {
        if (!context.mounted) return;
        // open sas.keys_exchanged dialog
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) => SasKeysExchangedPage(
            sender: event.sender(),
            isVerifier: _isVerifier,
            emojis: emojis,
            onCancel: (BuildContext context) async {
              await event.cancelSasVerification();
            },
            onMatch: (BuildContext context) async {
              _log.info('sas.keys_exchanged - match');
              await event.confirmSasVerification();
            },
            onMismatch: (BuildContext context) async {
              _log.info('sas.keys_exchanged - mismatch');
              await event.mismatchSasVerification();
            },
          ),
          isDismissible: false,
        );
      });
    }
  }

  void onSasConfirmed(BuildContext context, VerificationEvent event) {
    _log.info('emitter sas.confirmed');

    // // close dialog from previous stage, ex: sas.keys_exchanged
    // final nav = Navigator.of(context, rootNavigator: true);
    // if (nav.canPop()) nav.pop();

    // // handle sas.confirmed event without dialog
    // Future.delayed(const Duration(milliseconds: 500), () async {
    //   await event.reviewVerificationMac();
    // });
  }

  void onSasDone(BuildContext context, VerificationEvent event) {
    _log.info('emitter sas.done');
    if (_flowId == null) {
      return; // already finished due to request.done happened just before
    }
    _flowId = null;

    // close dialog from previous stage, ex: sas.confirmed
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();

    // open sas.done dialog
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => SasDonePage(
        sender: event.sender(),
        isVerifier: _isVerifier,
        onDone: (BuildContext context) => emitEvent('verification.init'),
      ),
      isDismissible: false,
    );
  }

  void emitEvent<T>(String type, [T? data]) {
    _verifEmitter.emit<T>(type, data);
  }
}
