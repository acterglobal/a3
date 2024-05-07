import 'package:acter/common/dialogs/logout_confirmation.dart';
import 'package:acter/common/notifications/notifications.dart';
import 'package:acter/common/providers/keyboard_visbility_provider.dart';
import 'package:acter/common/themes/app_theme.dart';

import 'package:acter/common/tutorial_dialogs/bottom_navigation_tutorials/bottom_navigation_tutorials.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/device.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/cross_signing/widgets/cross_signing.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/home/providers/navigation.dart';
import 'package:acter/features/home/widgets/sidebar_widget.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:dart_date/dart_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shake/shake.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

import 'package:logging/logging.dart';

final _log = Logger('a3::home::home_shell');

ScreenshotController screenshotController = ScreenshotController();
bool bugReportOpen = false;

Future<void> openBugReport(BuildContext context) async {
  if (bugReportOpen) {
    return;
  }
  final cacheDir = await appCacheDir();
  // rage shake disallows dot in filename
  int timestamp = DateTime.now().timestamp;
  final imagePath = await screenshotController.captureAndSave(
    cacheDir,
    fileName: 'screenshot_$timestamp.png',
  );
  if (context.mounted) {
    bugReportOpen = true;
    await context.pushNamed(
      Routes.bugReport.name,
      queryParameters: imagePath != null ? {'screenshot': imagePath} : {},
    );
    bugReportOpen = false;
  } else {
    // ignore: avoid_print
    print('not mounted :(');
  }
}

class HomeShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const HomeShell({super.key, required this.navigationShell});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => HomeShellState();
}

class HomeShellState extends ConsumerState<HomeShell> {
  final GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();
  late ShakeDetector detector;

  @override
  void initState() {
    super.initState();
    initShake();
    initNotifications();
    Future.delayed(
      const Duration(seconds: 1),
      () => bottomNavigationTutorials(context: context),
    );
  }

  Future<void> initShake() async {
    // shake is possible in only actual mobile devices
    if (await isRealPhone()) {
      detector = ShakeDetector.waitForStart(
        onPhoneShake: () {
          openBugReport(context);
        },
      );
      detector.startListening();
    }
  }

  Future<void> initNotifications() async {
    ref.listenManual(clientProvider, (previous, next) {
      if (next != null) {
        if (!ref.read(
          isActiveProvider(LabsFeature.mobilePushNotifications),
        )) {
          return;
        }
        _log.info('Attempting to ask for push notifications');
        setupPushNotifications(next);
        return;
      }
    });
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
    final syncState = ref.watch(syncStateProvider);
    final hasFirstSynced = !syncState.initialSync;
    final errorMsg = syncState.errorMsg;

    if (errorMsg != null) {
      final softLogout = errorMsg == 'SoftLogout';
      if (softLogout || errorMsg == 'Unauthorized') {
        // We have a special case
        return Scaffold(
          body: Container(
            margin: const EdgeInsets.only(top: kToolbarHeight),
            child: Center(
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 15),
                    height: 100,
                    width: 100,
                    child: SvgPicture.asset(
                      'assets/images/undraw_access_denied_re_awnf.svg',
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 15),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: L10n.of(context).access,
                        style: Theme.of(context).textTheme.headlineLarge,
                        children: <TextSpan>[
                          TextSpan(
                            text: ' ${L10n.of(context).denied}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 15),
                    child: Text(
                      L10n.of(context).yourSessionHasBeenTerminatedByServer,
                    ),
                  ),
                  softLogout
                      ? OutlinedButton(
                          onPressed: onLoginAgain,
                          child: Text(L10n.of(context).loginAgain),
                        )
                      : OutlinedButton(
                          onPressed: onClearDB,
                          child: Text(L10n.of(context).clearDBAndReLogin),
                        ),
                ],
              ),
            ),
          ),
        );
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
                  child: buildBody(context, hasFirstSynced),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void onLoginAgain() {
    // FIXME: not yet properly supported
    context.goNamed(Routes.intro.name);
  }

  void onClearDB() {
    logoutConfirmationDialog(context, ref);
  }

  Widget buildBody(BuildContext context, bool hasFirstSynced) {
    final keyboardVisibility = ref.watch(keyboardVisibleProvider);
    final bottomBarNav = ref.watch(bottomBarNavProvider(context));
    return AdaptiveLayout(
      key: _key,
      topNavigation: !hasFirstSynced
          ? SlotLayout(
              config: <Breakpoint, SlotLayoutConfig?>{
                Breakpoints.smallAndUp: SlotLayout.from(
                  key: const Key('LoadingIndicator'),
                  builder: (BuildContext ctx) {
                    return LinearProgressIndicator(
                      semanticsLabel: L10n.of(context).loadingFirstSync,
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
      bottomNavigation: !isDesktop && keyboardVisibility.valueOrNull != true
          ? SlotLayout(
              config: <Breakpoint, SlotLayoutConfig>{
                //In desktop, we have ability to adjust windows res,
                // adjust to navbar as primary to smaller views.
                Breakpoints.smallAndUp: SlotLayout.from(
                  key: Keys.mainNav,
                  inAnimation: AdaptiveScaffold.bottomToTop,
                  outAnimation: AdaptiveScaffold.topToBottom,
                  builder: (BuildContext ctx) => Stack(
                    children: [
                      SizedBox(
                        height: 50,
                        child: Row(
                          children: bottomBarNav
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
                            initialLocation:
                                index == widget.navigationShell.currentIndex,
                          );
                        },
                        items: bottomBarNav,
                        type: BottomNavigationBarType.fixed,
                      ),
                    ],
                  ),
                ),
              },
            )
          : null,
    );
  }

  void onBottomNavigated(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}
