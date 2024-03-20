import 'package:acter/common/providers/keyboard_visbility_provider.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/routes.dart';
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
import 'package:acter/features/home/providers/navigation.dart';
import 'package:acter/features/home/widgets/sidebar_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:screenshot/screenshot.dart';

final _log = Logger('a3::home::body');

const homeShellKey = Key('home-shell');
ScreenshotController screenshotController = ScreenshotController();

class HomeBody extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  final bool hasFirstSynced;

  const HomeBody({
    super.key = homeShellKey,
    required this.navigationShell,
    required this.hasFirstSynced,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => HomeBodyState();
}

class HomeBodyState extends ConsumerState<HomeBody> {
  final GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(verificationStateProvider, onStateChange);
    final bottomBarNav = ref.watch(bottomBarNavProvider(context));
    final keyboardVisibility = ref.watch(keyboardVisibleProvider);
    return CallbackShortcuts(
      bindings: <LogicalKeySet, VoidCallback>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK): () {
          context.pushNamed(Routes.quickJump.name);
        },
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK): () {
          context.pushNamed(Routes.quickJump.name);
        },
      },
      child: KeyboardDismissOnTap(
        // close keyboard if clicking somewhere else
        child: Scaffold(
          body: Screenshot(
            controller: screenshotController,
            child: AdaptiveLayout(
              key: _key,
              topNavigation: !widget.hasFirstSynced
                  ? SlotLayout(
                      config: <Breakpoint, SlotLayoutConfig?>{
                        Breakpoints.smallAndUp: SlotLayout.from(
                          key: const Key('LoadingIndicator'),
                          builder: (BuildContext ctx) {
                            return const LinearProgressIndicator(
                              semanticsLabel: 'Loading first sync',
                            );
                          },
                        ),
                      },
                    )
                  : null,
              primaryNavigation: isDesktop
                  ? SlotLayout(
                      config: <Breakpoint, SlotLayoutConfig?>{
                        // adapt layout according to platform.
                        Breakpoints.small: SlotLayout.from(
                          key: const Key('primaryNavigation'),
                          builder: (BuildContext ctx) => SidebarWidget(
                            labelType: NavigationRailLabelType.selected,
                            navigationShell: widget.navigationShell,
                          ),
                        ),
                        Breakpoints.mediumAndUp: SlotLayout.from(
                          key: const Key('primaryNavigation'),
                          builder: (BuildContext ctx) => SidebarWidget(
                            labelType: NavigationRailLabelType.all,
                            navigationShell: widget.navigationShell,
                          ),
                        ),
                      },
                    )
                  : null,
              body: SlotLayout(
                config: <Breakpoint, SlotLayoutConfig>{
                  Breakpoints.smallAndUp: SlotLayout.from(
                    key: const Key('Body Small'),
                    builder: (BuildContext ctx) => widget.navigationShell,
                  ),
                },
              ),
              bottomNavigation: !isDesktop &&
                      keyboardVisibility.valueOrNull != true
                  ? SlotLayout(
                      config: <Breakpoint, SlotLayoutConfig>{
                        //In desktop, we have ability to adjust windows res,
                        // adjust to navbar as primary to smaller views.
                        Breakpoints.smallAndUp: SlotLayout.from(
                          key: Keys.mainNav,
                          inAnimation: AdaptiveScaffold.bottomToTop,
                          outAnimation: AdaptiveScaffold.topToBottom,
                          builder: (BuildContext ctx) => BottomNavigationBar(
                            showSelectedLabels: false,
                            showUnselectedLabels: false,
                            currentIndex: widget.navigationShell.currentIndex,
                            onTap: (index) {
                              widget.navigationShell.goBranch(
                                index,
                                initialLocation: index ==
                                    widget.navigationShell.currentIndex,
                              );
                            },
                            items: bottomBarNav,
                            type: BottomNavigationBarType.fixed,
                          ),
                        ),
                      },
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  void onStateChange(VerificationState? prev, VerificationState next) {
    if (prev == next) return; // avoid too frequent callbacks
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
        onRequestReady(next.event!, next.isVerifier);
        break;
      case 'request.transitioned':
        onRequestTransitioned(next.event!);
        break;
      case 'request.done':
        onRequestDone(next.event!, next.isVerifier);
        break;
      case 'request.cancelled':
        onRequestCancelled(next.event!, next.isVerifier, next.flowId);
        break;
      case 'verification.request':
        onVerificationRequest(next.event!);
        break;
      case 'verification.ready':
        onVerificationReady(next.event!);
        break;
      case 'sas.started':
        onSasStarted(next.event!, next.isVerifier);
        break;
      case 'sas.accepted':
        onSasAccepted(next.event!, next.isVerifier);
        break;
      case 'sas.cancelled':
        onSasCancelled(next.event!, next.isVerifier, next.flowId);
        break;
      case 'sas.keys_exchanged':
        onSasKeysExchanged(next.event!, next.isVerifier, next.keysExchanged);
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
    final notifier = ref.read(verificationStateProvider.notifier);
    final flowId = event.flowId();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      notifier.changeState(isVerifier: true, flowId: flowId);
    });

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
  void onRequestRequested(VerificationEvent event) {
    _log.info('emitter request.requested');
  }

  // both of verifier & verifiee
  void onRequestReady(VerificationEvent event, bool isVerifier) {
    _log.info('emitter request.ready');

    // close dialog from previous stage, ex: verification.request
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();

    // open request.ready dialog
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => RequestReadyPage(
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

  void onRequestDone(VerificationEvent event, bool isVerifier) {
    _log.info('emitter request.done');
    final notifier = ref.read(verificationStateProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      notifier.changeState(flowId: null); // this event occurs before sas.done
    });

    // close dialog from previous stage, ex: sas.keys_exchanged
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();

    // open request.done dialog
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => RequestDonePage(
        sender: event.sender(),
        isVerifier: isVerifier,
        onDone: (BuildContext context) => notifier.finishFlow(),
      ),
      isDismissible: false,
    );
  }

  // both of verifier & verifiee get this event when verification was cancelled before start
  void onRequestCancelled(
    VerificationEvent event,
    bool isVerifier,
    String? flowId,
  ) {
    _log.info('emitter request.cancelled');
    if (flowId == null) {
      return; // already finished due to sas.cancelled happened just before
    }
    final notifier = ref.read(verificationStateProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      notifier.changeState(flowId: null);
    });

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
        isVerifier: isVerifier,
        message: reason,
        onDone: (BuildContext context) => notifier.finishFlow(),
      ),
      isDismissible: false,
    );
  }

  void onVerificationRequest(VerificationEvent event) {
    _log.info('emitter verification.request');

    // starting of verifiee's flow
    final notifier = ref.read(verificationStateProvider.notifier);
    final flowId = event.flowId();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      notifier.changeState(isVerifier: false, flowId: flowId);
    });

    // start request event loop
    final client = ref.read(alwaysClientProvider);
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

  void onVerificationReady(VerificationEvent event) {
    _log.info('emitter verification.ready');
  }

  // verifiee gets this event when verifier clicked start
  void onSasStarted(VerificationEvent event, bool isVerifier) {
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
        isVerifier: isVerifier,
        onCancel: (BuildContext context) async {
          await event.cancelSasVerification();
        },
      ),
      isDismissible: false,
    );
  }

  // verifiee gets this event when verifiee clicked start
  void onSasAccepted(VerificationEvent event, bool isVerifier) {
    _log.info('emitter sas.accepted');

    // close dialog from previous stage, ex: request.transitioned
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();

    // open sas.accept dialog
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => SasAcceptedPage(
        sender: event.sender(),
        isVerifier: isVerifier,
      ),
      isDismissible: false,
    );
  }

  // both of verifier & verifiee get this event when verification was cancelled after start
  void onSasCancelled(
    VerificationEvent event,
    bool isVerifier,
    String? flowId,
  ) {
    _log.info('emitter sas.cancelled');
    if (flowId == null) {
      return; // already finished due to request.cancelled happened just before
    }
    final notifier = ref.read(verificationStateProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      notifier.changeState(flowId: null);
    });

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
        isVerifier: isVerifier,
        message: reason,
        onDone: (BuildContext context) => notifier.finishFlow(),
      ),
      isDismissible: false,
    );
  }

  void onSasKeysExchanged(
    VerificationEvent event,
    bool isVerifier,
    bool keysExchanged,
  ) {
    _log.info('emitter sas.keys_exchanged');
    if (keysExchanged) {
      return; // skip 2nd occurrence of this event when other clicked match
    }
    final notifier = ref.read(verificationStateProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      notifier.changeState(keysExchanged: true);
    });

    // close dialog from previous stage, ex: sas.started
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();

    if (isVerifier) {
      // open sas.keys_exchanged dialog
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) => SasKeysExchangedPage(
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
          context: context,
          builder: (BuildContext context) => SasKeysExchangedPage(
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
}
