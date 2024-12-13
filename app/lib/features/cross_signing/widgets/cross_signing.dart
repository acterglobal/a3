import 'package:acter/features/cross_signing/providers/notifiers/verification_notifiers.dart';
import 'package:acter/features/cross_signing/providers/verification_providers.dart';
import 'package:acter/features/cross_signing/views/request_cancelled.dart';
import 'package:acter/features/cross_signing/views/request_created.dart';
import 'package:acter/features/cross_signing/views/request_done.dart';
import 'package:acter/features/cross_signing/views/request_ready.dart';
import 'package:acter/features/cross_signing/views/sas_accepted.dart';
import 'package:acter/features/cross_signing/views/sas_cancelled.dart';
import 'package:acter/features/cross_signing/views/sas_keys_exchanged.dart';
import 'package:acter/features/cross_signing/views/sas_started.dart';
import 'package:acter/features/cross_signing/views/verification_request.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::cross_signing::widget');

// this widget has no elements
// it just pops up stage dialogs for verification
@immutable
class CrossSigning extends ConsumerStatefulWidget {
  const CrossSigning({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => CrossSigningState();
}

class CrossSigningState extends ConsumerState<CrossSigning> {
  bool isVerifier = false; // whether this device requested verification
  String? flowId; // if not null, verification flying now
  bool keysExchanged = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(verificationStateProvider, onStateChange);
    return const SizedBox(width: 0, height: 0); // empty widget
  }

  void onStateChange(VerificationState? prev, VerificationState next) {
    switch (next.stage) {
      case 'verification.init':
        onVerificationInit();
        break;
      case 'request.created':
        onRequestCreated(next.event!);
        break;
      case 'request.requested':
        onRequestRequested(next.event!);
        break;
      case 'request.ready':
        onRequestReady(next.event!);
        break;
      case 'request.transitioned':
        onRequestTransitioned(next.event!);
        break;
      case 'request.done':
        onRequestDone(next.event!);
        break;
      case 'request.cancelled':
        onRequestCancelled(next.event!);
        break;
      case 'verification.request':
        onVerificationRequest(next.event!);
        break;
      case 'verification.ready':
        onVerificationReady(next.event!);
        break;
      case 'sas.started':
        onSasStarted(next.event!);
        break;
      case 'sas.accepted':
        onSasAccepted(next.event!);
        break;
      case 'sas.cancelled':
        onSasCancelled(next.event!);
        break;
      case 'sas.keys_exchanged':
        onSasKeysExchanged(next.event!);
        break;
      case 'sas.confirmed':
        onSasConfirmed(next.event!);
        break;
      case 'sas.done':
        onSasDone(next.event!);
        break;
    }
  }

  void onVerificationInit() {
    _log.info('emitter verification.init');

    // close dialog from previous stage, ex: sas.done
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();
  }

  // verifier
  void onRequestCreated(VerificationEvent event) {
    _log.info('emitter request.created');

    // starting of active verification
    setState(() {
      isVerifier = true;
      flowId = event.flowId();
    });

    // open request.created dialog
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => RequestCreatedView(
        onCancel: (BuildContext context) async {
          // cancel verification request launched by this device
          await event.cancelVerificationRequest();
        },
      ),
      isDismissible: false,
    );
  }

  // verifier
  void onRequestRequested(VerificationEvent event) {
    _log.info('emitter request.requested');
  }

  // both of verifier & verifiee
  void onRequestReady(VerificationEvent event) {
    _log.info('emitter request.ready');

    // close dialog from previous stage, ex: verification.request
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();

    // open request.ready dialog
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => RequestReadyView(
        isVerifier: isVerifier,
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

  void onRequestTransitioned(VerificationEvent event) {
    _log.info('emitter request.transitioned');

    // start sas event loop
    final client = ref.read(alwaysClientProvider);
    client.installSasEventHandler(event.flowId());
  }

  void onRequestDone(VerificationEvent event) {
    _log.info('emitter request.done');
    setState(() => flowId = null); // this event occurs before sas.done

    // close dialog from previous stage, ex: sas.keys_exchanged
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();

    // open request.done dialog
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => RequestDoneView(
        sender: event.sender(),
        isVerifier: isVerifier,
        onDone: onFlowFinished,
      ),
      isDismissible: false,
    );
  }

  // both of verifier & verifiee get this event when verification was cancelled before start
  void onRequestCancelled(VerificationEvent event) {
    _log.info('emitter request.cancelled');
    if (flowId == null) {
      return; // already finished due to sas.cancelled happened just before
    }
    setState(() => flowId = null);

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
      builder: (BuildContext context) => RequestCancelledView(
        sender: event.sender(),
        isVerifier: isVerifier,
        message: reason,
        onDone: onFlowFinished,
      ),
      isDismissible: false,
    );
  }

  void onVerificationRequest(VerificationEvent event) {
    _log.info('emitter verification.request');

    // starting of verifiee’s flow
    final fId = event.flowId();
    setState(() {
      isVerifier = false;
      flowId = fId;
    });

    // start request event loop
    final client = ref.read(alwaysClientProvider);
    client.installRequestEventHandler(fId);

    // open verification.request dialog
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => VerificationRequestView(
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

  void onVerificationReady(VerificationEvent event) {
    _log.info('emitter verification.ready');
  }

  // verifiee gets this event when verifier clicked start
  void onSasStarted(VerificationEvent event) {
    _log.info('emitter sas.started');

    // close dialog from previous stage, ex: request.transitioned
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();

    // accept sas that verifier started
    event.acceptSasVerification();

    // open sas.started dialog
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => SasStartedView(
        isVerifier: isVerifier,
        onCancel: (BuildContext context) async {
          await event.cancelSasVerification();
        },
      ),
      isDismissible: false,
    );
  }

  // verifiee gets this event when verifiee clicked start
  void onSasAccepted(VerificationEvent event) {
    _log.info('emitter sas.accepted');

    // close dialog from previous stage, ex: request.transitioned
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();

    // open sas.accept dialog
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => SasAcceptedView(
        sender: event.sender(),
        isVerifier: isVerifier,
      ),
      isDismissible: false,
    );
  }

  // both of verifier & verifiee get this event when verification was cancelled after start
  void onSasCancelled(VerificationEvent event) {
    _log.info('emitter sas.cancelled');
    if (flowId == null) {
      return; // already finished due to request.cancelled happened just before
    }
    setState(() => flowId = null);

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
      builder: (BuildContext context) => SasCancelledView(
        sender: event.sender(),
        isVerifier: isVerifier,
        message: reason,
        onDone: onFlowFinished,
      ),
      isDismissible: false,
    );
  }

  void onSasKeysExchanged(VerificationEvent event) {
    _log.info('emitter sas.keys_exchanged');
    if (keysExchanged) {
      return; // skip 2nd occurrence of this event when other clicked match
    }
    setState(() => keysExchanged = true);

    // close dialog from previous stage, ex: sas.started
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();

    if (isVerifier) {
      // open sas.keys_exchanged dialog
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) => SasKeysExchangedView(
          sender: event.sender(),
          isVerifier: isVerifier,
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
          // ignore: use_build_context_synchronously
          context: context,
          builder: (BuildContext context) => SasKeysExchangedView(
            sender: event.sender(),
            isVerifier: isVerifier,
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

  void onSasConfirmed(VerificationEvent event) {
    _log.info('emitter sas.confirmed');
  }

  void onSasDone(VerificationEvent event) {
    _log.info('emitter sas.done');
  }

  void onFlowFinished(BuildContext context) {
    setState(() {
      isVerifier = false;
      flowId = null;
      keysExchanged = false;
    });
    ref.read(verificationStateProvider.notifier).finishFlow();
  }
}
