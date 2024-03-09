import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/cross_signing/pages/verification_accept.dart';
import 'package:acter/features/cross_signing/pages/verification_cancel.dart';
import 'package:acter/features/cross_signing/pages/verification_done.dart';
import 'package:acter/features/cross_signing/pages/verification_launch.dart';
import 'package:acter/features/cross_signing/pages/verification_key.dart';
import 'package:acter/features/cross_signing/pages/verification_ready.dart';
import 'package:acter/features/cross_signing/pages/verification_request.dart';
import 'package:acter/features/cross_signing/pages/verification_start.dart';
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

final _log = Logger('a3::home::home_body');

ScreenshotController screenshotController = ScreenshotController();

// we use ConsumerStatefulWidget, because we don't call setState here but we need dispose fn
class HomeBody extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  final bool keyboardVisible;
  final bool hasFirstSynced;

  const HomeBody({
    super.key,
    required this.navigationShell,
    required this.keyboardVisible,
    required this.hasFirstSynced,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => HomeBodyState();
}

class HomeBodyState extends ConsumerState<HomeBody> {
  final GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    super.dispose();

    final verifEmitter = ref.read(syncStateProvider.notifier).verifEmitter;
    verifEmitter.off(type: 'verification.init');
    verifEmitter.off(type: 'verification.launch');
    verifEmitter.off(type: 'verification.request');
    verifEmitter.off(type: 'verification.ready');
    verifEmitter.off(type: 'verification.start');
    verifEmitter.off(type: 'verification.accept');
    verifEmitter.off(type: 'verification.cancel');
    verifEmitter.off(type: 'verification.key');
    verifEmitter.off(type: 'verification.mac');
    verifEmitter.off(type: 'verification.done');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(syncStateProvider, (prev, next) {
      _log.info('initialSync - ${next.initialSync}');
      if (next.initialSync) return;
      final verifEmitter = ref.read(syncStateProvider.notifier).verifEmitter;
      verifEmitter.on('verification.init', (_) {
        onVerifInit(context);
      });
      verifEmitter.on<String>('verification.launch', (verifId) {
        onVerifLaunch(context, verifId);
      });
      verifEmitter.on<VerificationEvent>('verification.request', (event) {
        onVerifRequest(context, event);
      });
      verifEmitter.on<VerificationEvent>('verification.ready', (event) {
        onVerifReady(context, event);
      });
      verifEmitter.on<VerificationEvent>('verification.start', (event) {
        onVerifStart(context, event);
      });
      verifEmitter.on<VerificationEvent>('verification.accept', (event) {
        onVerifAccept(context, event);
      });
      verifEmitter.on<VerificationEvent>('verification.cancel', (event) {
        onVerifCancel(context, event);
      });
      verifEmitter.on<VerificationEvent>('verification.key', (event) {
        onVerifKey(context, event);
      });
      verifEmitter.on<VerificationEvent>('verification.mac', (event) {
        onVerifMac(context, event);
      });
      verifEmitter.on<VerificationEvent>('verification.done', (event) {
        onVerifDone(context, event);
      });
    });

    final bottomBarNav = ref.watch(bottomBarNavProvider(context));
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
                          builder: (BuildContext ctx) =>
                              const LinearProgressIndicator(
                            semanticsLabel: 'Loading first sync',
                          ),
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
              bottomNavigation: !isDesktop && !widget.keyboardVisible
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

  void handleBottomNavigation(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
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
    ref.read(syncStateProvider.notifier).activeVerifId = verifId;

    // open verification.launch dialog
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => VerificationLaunchPage(
        onCancel: (BuildContext context) async {
          // cancel verification request launched by this device
          final notifier = ref.read(syncStateProvider.notifier);
          if (notifier.isActiveVerif()) {
            final client = ref.read(alwaysClientProvider);
            final manager = client.sessionManager();
            await manager.terminateVerification(notifier.activeVerifId!);
          }
        },
      ),
      isDismissible: false,
    );
  }

  void onVerifRequest(BuildContext context, VerificationEvent event) {
    _log.info('emitter verification.request');

    // starting of passive verification
    ref.read(syncStateProvider.notifier).activeVerifId = null;

    // open verification.request dialog
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => VerificationRequestPage(
        sender: event.sender(),
        passive: ref.read(syncStateProvider.notifier).isPassiveVerif(),
        onCancel: (BuildContext context) async {
          // cancel verification request from other device
          await event.cancelVerificationRequest();
        },
        onAccept: (BuildContext context) async {
          // accept verification request from other device
          await event.acceptVerificationRequest();
          // go to onReady stage and wait for other's ready
          Future.delayed(const Duration(milliseconds: 500), () {
            final notifier = ref.read(syncStateProvider.notifier);
            notifier.verifEmitter.emit('verification.ready', event);
          });
        },
      ),
      isDismissible: false,
    );
  }

  void onVerifReady(BuildContext context, VerificationEvent event) {
    _log.info('emitter verification.ready');

    // close dialog from previous stage, ex: verification.launch
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();

    // open verification.ready dialog
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => VerificationReadyPage(
        passive: ref.read(syncStateProvider.notifier).isPassiveVerif(),
        onCancel: (BuildContext context) async {
          await event.cancelVerificationRequest();
        },
        onAccept: (BuildContext context) async {
          // start sas verification from this device
          await event.startSasVerification();
          // go to onStart stage
          Future.delayed(const Duration(milliseconds: 500), () {
            final notifier = ref.read(syncStateProvider.notifier);
            notifier.verifEmitter.emit('verification.start', event);
          });
        },
      ),
      isDismissible: false,
    );
  }

  void onVerifStart(BuildContext context, VerificationEvent event) {
    _log.info('emitter verification.start');

    // close dialog from previous stage, ex: verification.ready
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();

    // open verification.start dialog
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => VerificationStartPage(
        passive: ref.read(syncStateProvider.notifier).isPassiveVerif(),
        onCancel: (BuildContext context) async {
          await event.cancelSasVerification();
        },
      ),
      isDismissible: false,
    );
    // if (ref.read(syncStateProvider.notifier).isActiveVerif()) {
    // accept the sas verification that other device started
    Future.delayed(const Duration(milliseconds: 500), () async {
      await event.acceptSasVerification();
    });
    // }
  }

  void onVerifAccept(BuildContext context, VerificationEvent event) {
    _log.info('emitter verification.accept');

    // close dialog from previous stage, ex: verification.start
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();

    // open verification.accept dialog
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => VerificationAcceptPage(
        sender: event.sender(),
        passive: ref.read(syncStateProvider.notifier).isPassiveVerif(),
      ),
      isDismissible: false,
    );
  }

  void onVerifCancel(BuildContext context, VerificationEvent event) {
    _log.info('emitter verification.cancel');

    // close dialog from previous stage, ex: verification.key
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();

    // [ref] https://spec.matrix.org/unstable/client-server-api/#mkeyverificationcancel
    var reason = event.getContent('reason');
    if (reason == 'Mismatched short authentication string') {
      reason =
          'You cancelled verification. Start verification again from the notification.';
    }
    // open verification.cancel dialog
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => VerificationCancelPage(
        sender: event.sender(),
        passive: ref.read(syncStateProvider.notifier).isPassiveVerif(),
        message: reason,
        onDone: (BuildContext context) => resetVerifStage(),
      ),
      isDismissible: false,
    );
  }

  void onVerifKey(BuildContext context, VerificationEvent event) {
    _log.info('emitter verification.key');

    // close dialog from previous stage, ex: verification.start
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();

    if (ref.read(syncStateProvider.notifier).isPassiveVerif()) {
      // fetch emojis
      event.getEmojis().then((emojis) {
        // open verification.key dialog
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) => VerificationKeyPage(
            sender: event.sender(),
            passive: ref.read(syncStateProvider.notifier).isPassiveVerif(),
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
          passive: ref.read(syncStateProvider.notifier).isPassiveVerif(),
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

  void onVerifMac(BuildContext context, VerificationEvent event) {
    _log.info('emitter verification.mac');

    // close dialog from previous stage, ex: verification.key
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();

    // handle verification.mac event without dialog
    Future.delayed(const Duration(milliseconds: 500), () async {
      await event.reviewVerificationMac();
    });
  }

  void onVerifDone(BuildContext context, VerificationEvent event) {
    _log.info('emitter verification.done');

    // close dialog from previous stage, ex: verification.mac
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();

    // open verification.done dialog
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => VerificationDonePage(
        sender: event.sender(),
        passive: ref.read(syncStateProvider.notifier).isPassiveVerif(),
        onDone: (BuildContext context) => resetVerifStage(),
      ),
      isDismissible: false,
    );
  }

  void resetVerifStage() {
    final notifier = ref.read(syncStateProvider.notifier);
    notifier.verifEmitter.emit('verification.init');
  }
}
