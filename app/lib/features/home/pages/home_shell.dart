import 'package:acter/common/dialogs/logout_confirmation.dart';
import 'package:acter/common/providers/keyboard_visbility_provider.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/device.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/home/providers/navigation.dart';
import 'package:acter/features/home/widgets/sidebar_widget.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:dart_date/dart_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shake/shake.dart';

const homeShellKey = Key('home-shell');
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

  const HomeShell({super.key = homeShellKey, required this.navigationShell});

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

  @override
  Widget build(BuildContext context) {
    // get platform of context.
    final client = ref.watch(clientProvider);
    if (client == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    final syncState = ref.watch(syncStateProvider);
    final hasFirstSynced = !syncState.initialSync;
    final errorMsg = syncState.errorMsg;
    final keyboardVisibility = ref.watch(keyboardVisibleProvider);

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
                      text: const TextSpan(
                        text: 'Access',
                        style: TextStyle(color: Colors.white, fontSize: 32),
                        children: <TextSpan>[
                          TextSpan(
                            text: ' Denied',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              fontSize: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 15),
                    child: const Text(
                      'Your session has been terminated by the server, you need to log in again',
                    ),
                  ),
                  softLogout
                      ? OutlinedButton(
                          // FIXME: not yet properly supported
                          onPressed: () => context.goNamed(Routes.intro.name),
                          child: const Text(
                            'Login again',
                          ),
                        )
                      : OutlinedButton(
                          onPressed: () =>
                              logoutConfirmationDialog(context, ref),
                          child: const Text('Clear db and re-login'),
                        ),
                ],
              ),
            ),
          ),
        );
      }
    }

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
              topNavigation: !hasFirstSynced
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
              bottomNavigation: !isDesktop &&
                      keyboardVisibility.valueOrNull !=
                          true // and the keyboard is not visible.
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
}
