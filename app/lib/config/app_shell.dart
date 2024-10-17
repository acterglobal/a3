import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/keyboard_visbility_provider.dart';
import 'package:acter/common/tutorial_dialogs/bottom_navigation_tutorials/bottom_navigation_tutorials.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/device.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/config/notifications/init.dart';
import 'package:acter/features/auth/pages/logged_out_screen.dart';
import 'package:acter/features/bug_report/actions/open_bug_report.dart';
import 'package:acter/features/bug_report/providers/bug_report_providers.dart';
import 'package:acter/features/calendar_sync/calendar_sync.dart';
import 'package:acter/features/cross_signing/widgets/cross_signing.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/home/providers/navigation.dart';
import 'package:acter/features/home/widgets/sidebar_widget.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shake_detector/shake_detector.dart';

final _log = Logger('a3::config::home_shell');

final ScreenshotController screenshotController = ScreenshotController();

class AppShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => AppShellState();
}

class AppShellState extends ConsumerState<AppShell> {
  final GlobalKey<ScaffoldState> _key =
      GlobalKey<ScaffoldState>(debugLabel: 'home shell scaffold');
  late ShakeDetector detector;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // no wait goes there
    Future.delayed(
      const Duration(seconds: 1),
      // ignore: use_build_context_synchronously
      () => bottomNavigationTutorials(context: context),
    );
    initShake();

    // these want to be sure to execute in order
    await _initNotifications();
    // calendar sync
    await _initCalendarSync();
  }

  Future<void> initShake() async {
    // shake is possible in only actual mobile devices
    if (isBugReportingEnabled && await isRealPhone()) {
      detector = ShakeDetector.autoStart(
        shakeThresholdGravity: 30.0,
        onShake: () {
          openBugReport(context);
        },
      );
    }
  }

  Future<void> _initNotifications() async {
    final client = ref.read(clientProvider);
    if (client != null) {
      _initPushForClient(client);
    }
    ref.listenManual(clientProvider, (previous, next) {
      if (next != null) {
        _initPushForClient(next);
      }
    });
  }

  Future<void> _initCalendarSync() async {
    final client = ref.read(clientProvider);
    if (client != null) {
      // calendar sync only works if we have a client
      await initCalendarSync();
    }
    ref.listenManual(clientProvider, (previous, next) {
      if (next != null) {
        initCalendarSync();
      }
    });
  }

  Future<void> _initPushForClient(Client client) async {
    final pushActive =
        ref.read(isActiveProvider(LabsFeature.mobilePushNotifications));
    if (!pushActive) return;
    _log.info('Attempting to ask for push notifications');
    setupPushNotifications(client);
  }

  @override
  Widget build(BuildContext context) {
    // get platform of context.
    if (ref.watch(clientProvider) == null) {
      // at the very startup we might not yet have a client loaded
      // show a loading spinner meanwhile.
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    final errorMsg = ref.watch(syncStateProvider.select((v) => v.errorMsg));
    if (errorMsg != null) {
      final softLogout = errorMsg == 'SoftLogout';
      if (softLogout || errorMsg == 'Unauthorized') {
        return LoggedOutScreen(softLogout: softLogout);
      }
    }

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
            child: Column(
              children: [
                const CrossSigning(),
                Expanded(
                  child: buildBody(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget topNavigationWidget(BuildContext context) {
    if (ref.watch(hasFirstSyncedProvider)) {
      return const SizedBox.shrink();
    }
    return LinearProgressIndicator(
      semanticsLabel: L10n.of(context).loadingFirstSync,
    );
  }

  SlotLayout topNavigationLayout() {
    return SlotLayout(
      config: <Breakpoint, SlotLayoutConfig?>{
        Breakpoints.smallAndUp: SlotLayout.from(
          key: const Key('LoadingIndicator'),
          builder: topNavigationWidget,
        ),
      },
    );
  }

  SlotLayout primaryNavigationLayout() {
    return SlotLayout(
      config: <Breakpoint, SlotLayoutConfig?>{
        Breakpoints.mediumLargeAndUp: SlotLayout.from(
          key: const Key('primaryNavigation'),
          builder: (BuildContext context) => SidebarWidget(
            navigationShell: widget.navigationShell,
          ),
        ),
      },
    );
  }

  SlotLayout bodySlot() {
    return SlotLayout(
      config: <Breakpoint, SlotLayoutConfig>{
        Breakpoints.standard: SlotLayout.from(
          key: const Key('Body Small'),
          builder: (BuildContext context) => widget.navigationShell,
        ),
      },
    );
  }

  Widget bottomNavigationWidget(BuildContext context) {
    final keyboardVisibility = ref.watch(keyboardVisibleProvider);
    if (keyboardVisibility.valueOrNull != false) {
      return const SizedBox.shrink();
    }
    return Stack(
      children: [
        SizedBox(
          height: 50,
          child: Row(
            children: bottomBarItems
                .map(
                  (bottomBarNav) => Expanded(
                    child: Center(
                      child: SizedBox(
                        key: bottomBarNav.tutorialGlobalKey,
                        height: 40,
                        width: 40,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        BottomNavigationBar(
          showSelectedLabels: false,
          showUnselectedLabels: false,
          currentIndex: widget.navigationShell.currentIndex,
          onTap: (index) {
            widget.navigationShell.goBranch(
              index,
              initialLocation: index == widget.navigationShell.currentIndex,
            );
          },
          items: bottomBarItems,
          type: BottomNavigationBarType.fixed,
        ),
      ],
    );
  }

  SlotLayout bottomNavigationLayout() {
    return SlotLayout(
      config: <Breakpoint, SlotLayoutConfig>{
        Breakpoints.small: SlotLayout.from(
          key: Keys.mainNav,
          inAnimation: AdaptiveScaffold.bottomToTop,
          outAnimation: AdaptiveScaffold.topToBottom,
          builder: bottomNavigationWidget,
        ),
        Breakpoints.medium: SlotLayout.from(
          key: Keys.mainNav,
          inAnimation: AdaptiveScaffold.bottomToTop,
          outAnimation: AdaptiveScaffold.topToBottom,
          builder: bottomNavigationWidget,
        ),
      },
    );
  }

  Widget buildBody(BuildContext context) {
    return AdaptiveLayout(
      key: _key,
      topNavigation: topNavigationLayout(),
      primaryNavigation: primaryNavigationLayout(),
      body: bodySlot(),
      bottomNavigation: bottomNavigationLayout(),
    );
  }
}
