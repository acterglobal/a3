import 'dart:async';

import 'package:acter/features/cross_signing/pages/verification_accept.dart';
import 'package:acter/features/cross_signing/pages/verification_cancel.dart';
import 'package:acter/features/cross_signing/pages/verification_done.dart';
import 'package:acter/features/cross_signing/pages/verification_launch.dart';
import 'package:acter/features/cross_signing/pages/verification_key.dart';
import 'package:acter/features/cross_signing/pages/verification_ready.dart';
import 'package:acter/features/cross_signing/pages/verification_request.dart';
import 'package:acter/features/cross_signing/pages/verification_start.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:events_emitter/events_emitter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::cross_signing');

class CrossSigning {
  final ffi.Client client;
  final Ref ref;

  final EventEmitter _verifEmitter = EventEmitter();
  String? _activeId;
  Stream<ffi.VerificationEvent>? _verifListener;
  StreamSubscription<ffi.VerificationEvent>? _verifPoller;

  CrossSigning(this.client, this.ref) {
    _verifListener = client.verificationEventRx(); // keep it resident in memory
    _verifPoller = _verifListener?.listen((event) {
      String eventType = event.eventType();
      _log.info('$eventType - flow_id: ${event.flowId()}');
      switch (eventType) {
        case 'm.key.verification.request':
          _verifEmitter.emit('verification.request', event);
          break;
        case 'm.key.verification.ready':
          _verifEmitter.emit('verification.ready', event);
          break;
        // case 'm.key.verification.start':
        case 'SasState::Started':
          _verifEmitter.emit('verification.start', event);
          break;
        // case 'm.key.verification.cancel':
        case 'SasState::Cancelled':
          _verifEmitter.emit('verification.cancel', event);
          break;
        // case 'm.key.verification.accept':
        case 'SasState::Accepted':
          _verifEmitter.emit('verification.accept', event);
          break;
        // case 'm.key.verification.key':
        case 'SasState::KeysExchanged':
          _verifEmitter.emit('verification.key', event);
          break;
        // case 'm.key.verification.mac':
        case 'SasState::Confirmed':
          _verifEmitter.emit('verification.mac', event);
          break;
        // case 'm.key.verification.done':
        case 'SasState::Done':
          _verifEmitter.emit('verification.done', event);
          break;
      }
    });
    ref.onDispose(() => _verifPoller?.cancel());
  }

  String getActiveId() {
    return _activeId!;
  }

  bool isActive() {
    return _activeId != null;
  }

  bool isPassive() {
    return _activeId == null;
  }

  void installEventFilter(BuildContext context) {
    _verifEmitter.on('verification.init', (_) {
      onVerifInit(context);
    });
    _verifEmitter.on<String>('verification.launch', (verifId) {
      if (context.mounted) onVerifLaunch(context, verifId);
    });
    _verifEmitter.on<ffi.VerificationEvent>('verification.request', (event) {
      if (context.mounted) onVerifRequest(context, event);
    });
    _verifEmitter.on<ffi.VerificationEvent>('verification.ready', (event) {
      if (context.mounted) onVerifReady(context, event);
    });
    _verifEmitter.on<ffi.VerificationEvent>('verification.start', (event) {
      if (context.mounted) onVerifStart(context, event);
    });
    _verifEmitter.on<ffi.VerificationEvent>('verification.accept', (event) {
      if (context.mounted) onVerifAccept(context, event);
    });
    _verifEmitter.on<ffi.VerificationEvent>('verification.cancel', (event) {
      if (context.mounted) onVerifCancel(context, event);
    });
    _verifEmitter.on<ffi.VerificationEvent>('verification.key', (event) {
      if (context.mounted) onVerifKey(context, event);
    });
    _verifEmitter.on<ffi.VerificationEvent>('verification.mac', (event) {
      if (context.mounted) onVerifMac(context, event);
    });
    _verifEmitter.on<ffi.VerificationEvent>('verification.done', (event) {
      if (context.mounted) onVerifDone(context, event);
    });
  }

  void removeEventFilter() {
    _verifEmitter.off(type: 'verification.init');
    _verifEmitter.off(type: 'verification.launch');
    _verifEmitter.off(type: 'verification.request');
    _verifEmitter.off(type: 'verification.ready');
    _verifEmitter.off(type: 'verification.start');
    _verifEmitter.off(type: 'verification.accept');
    _verifEmitter.off(type: 'verification.cancel');
    _verifEmitter.off(type: 'verification.key');
    _verifEmitter.off(type: 'verification.mac');
    _verifEmitter.off(type: 'verification.done');
  }

  void onVerifInit(BuildContext context) {
    _log.info('emitter verification.init');

    // close dialog from previous stage, ex: verification.done
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();
  }

  void onVerifLaunch(BuildContext context, String verifId) {
    _log.info('emitter verification.launch');

    // starting of active verification
    _activeId = verifId;

    // open verification.launch dialog
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => VerificationLaunchPage(
        onCancel: (BuildContext context) async {
          // cancel verification request launched by this device
          if (isActive()) {
            final client = ref.read(alwaysClientProvider);
            final manager = client.sessionManager();
            await manager.terminateVerification(getActiveId());
          }
        },
      ),
      isDismissible: false,
    );
  }

  void onVerifRequest(BuildContext context, ffi.VerificationEvent event) {
    _log.info('emitter verification.request');

    // starting of passive verification
    _activeId = null;

    // open verification.request dialog
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => VerificationRequestPage(
        sender: event.sender(),
        passive: isPassive(),
        onCancel: (BuildContext context) async {
          // cancel verification request from other device
          await event.cancelVerificationRequest();
        },
        onAccept: (BuildContext context) async {
          // accept verification request from other device
          await event.acceptVerificationRequest();
          // go to onReady stage and wait for other's ready
          Future.delayed(const Duration(milliseconds: 500), () {
            _verifEmitter.emit('verification.ready', event);
          });
        },
      ),
      isDismissible: false,
    );
  }

  void onVerifReady(BuildContext context, ffi.VerificationEvent event) {
    _log.info('emitter verification.ready');

    // close dialog from previous stage, ex: verification.launch
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();

    // open verification.ready dialog
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => VerificationReadyPage(
        passive: isPassive(),
        onCancel: (BuildContext context) async {
          await event.cancelVerificationRequest();
        },
        onAccept: (BuildContext context) async {
          // start sas verification from this device
          await event.startSasVerification();
          // go to onStart stage
          Future.delayed(const Duration(milliseconds: 500), () {
            _verifEmitter.emit('verification.start', event);
          });
        },
      ),
      isDismissible: false,
    );
  }

  void onVerifStart(BuildContext context, ffi.VerificationEvent event) {
    _log.info('emitter verification.start');

    // close dialog from previous stage, ex: verification.ready
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();

    // open verification.start dialog
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => VerificationStartPage(
        passive: isPassive(),
        onCancel: (BuildContext context) async {
          await event.cancelSasVerification();
        },
      ),
      isDismissible: false,
    );
    // if (isActive()) {
    // accept the sas verification that other device started
    Future.delayed(const Duration(milliseconds: 500), () async {
      await event.acceptSasVerification();
    });
    // }
  }

  void onVerifAccept(BuildContext context, ffi.VerificationEvent event) {
    _log.info('emitter verification.accept');

    // close dialog from previous stage, ex: verification.start
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();

    // open verification.accept dialog
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => VerificationAcceptPage(
        sender: event.sender(),
        passive: isPassive(),
      ),
      isDismissible: false,
    );
  }

  void onVerifCancel(BuildContext context, ffi.VerificationEvent event) {
    _log.info('emitter verification.cancel');

    // close dialog from previous stage, ex: verification.key
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();

    // [ref] https://spec.matrix.org/unstable/client-server-api/#mkeyverificationcancel
    var reason = event.getContent('reason');
    if (reason == 'Unknown cancel reason') {
      reason = null;
    }
    // open verification.cancel dialog
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => VerificationCancelPage(
        sender: event.sender(),
        passive: isPassive(),
        message: reason,
        onDone: (BuildContext context) => emitEvent('verification.init'),
      ),
      isDismissible: false,
    );
  }

  void onVerifKey(BuildContext context, ffi.VerificationEvent event) {
    _log.info('emitter verification.key');

    // close dialog from previous stage, ex: verification.start
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();

    if (isPassive()) {
      // fetch emojis
      event.getEmojis().then((emojis) {
        if (!context.mounted) return;
        // open verification.key dialog
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) => VerificationKeyPage(
            sender: event.sender(),
            passive: isPassive(),
            emojis: emojis,
            onCancel: (BuildContext context) async {
              await event.cancelSasVerification();
            },
            onMatch: (BuildContext context) async {
              _log.info('verification.key - match');
              await event.confirmSasVerification();
            },
            onMismatch: (BuildContext context) async {
              _log.info('verification.key - mismatch');
              await event.mismatchSasVerification();
            },
          ),
          isDismissible: false,
        );
      });
    } else {
      // open verification.key dialog
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) => VerificationKeyPage(
          sender: event.sender(),
          passive: isPassive(),
          emojis: event.emojis(),
          onCancel: (BuildContext context) async {
            await event.cancelSasVerification();
          },
          onMatch: (BuildContext context) async {
            _log.info('verification.key - match');
            await event.confirmSasVerification();
          },
          onMismatch: (BuildContext context) async {
            _log.info('verification.key - mismatch');
            await event.mismatchSasVerification();
          },
        ),
        isDismissible: false,
      );
    }
  }

  void onVerifMac(BuildContext context, ffi.VerificationEvent event) {
    _log.info('emitter verification.mac');

    // close dialog from previous stage, ex: verification.key
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();

    // handle verification.mac event without dialog
    Future.delayed(const Duration(milliseconds: 500), () async {
      await event.reviewVerificationMac();
    });
  }

  void onVerifDone(BuildContext context, ffi.VerificationEvent event) {
    _log.info('emitter verification.done');

    // close dialog from previous stage, ex: verification.mac
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();

    // open verification.done dialog
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => VerificationDonePage(
        sender: event.sender(),
        passive: isPassive(),
        onDone: (BuildContext context) => emitEvent('verification.init'),
      ),
      isDismissible: false,
    );
  }

  void emitEvent<T>(String type, [T? data]) {
    _verifEmitter.emit<T>(type, data);
  }
}
