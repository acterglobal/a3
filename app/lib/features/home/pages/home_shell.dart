import 'dart:io';

import 'package:acter/common/dialogs/logout_confirmation.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/features/activities/providers/notifications_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/home/providers/navigation.dart';
import 'package:acter/features/home/widgets/sidebar_widget.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jiffy/jiffy.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shake/shake.dart';

class HomeShell extends ConsumerStatefulWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  ScreenshotController screenshotController = ScreenshotController();
  final GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();
  late ShakeDetector detector;

  @override
  void initState() {
    super.initState();
    // shake is possible in only mobile
    if (Platform.isAndroid || Platform.isIOS) {
      detector = ShakeDetector.waitForStart(
        onPhoneShake: () {
          detector.stopListening();
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
    final hasFirstSynced = !syncState.syncing;
    final errorMsg = syncState.errorMsg;

    // we also need to globally hook the notifications list so it can issue
    // desktop notifications if configured.
    // ignore: unused_local_variable
    final notifications = ref.watch(notificationsListProvider);

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
      return Scaffold(
        body: Center(
          child: Text(errorMsg),
        ),
      );
    }

    final bottomBarNav = ref.watch(bottomBarNavProvider(context));
    final bottomBarIdx =
        ref.watch(currentSelectedBottomBarIndexProvider(context));
    return CallbackShortcuts(
      bindings: <LogicalKeySet, VoidCallback>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK): () {
          context.pushNamed(Routes.quickJump.name);
        },
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK): () {
          context.pushNamed(Routes.quickJump.name);
        },
      },
      child: Scaffold(
        body: Screenshot(
          controller: screenshotController,
          child: AdaptiveLayout(
            key: _key,
            topNavigation: !hasFirstSynced
                ? SlotLayout(
                    config: <Breakpoint, SlotLayoutConfig?>{
                      Breakpoints.smallAndUp: SlotLayout.from(
                        key: const Key('LoadingIndictor'),
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
                        builder: (BuildContext ctx) => const SidebarWidget(
                          labelType: NavigationRailLabelType.selected,
                        ),
                      ),
                      Breakpoints.mediumAndUp: SlotLayout.from(
                        key: const Key('primaryNavigation'),
                        builder: (BuildContext ctx) => const SidebarWidget(
                          labelType: NavigationRailLabelType.all,
                        ),
                      ),
                    },
                  )
                : null,
            body: SlotLayout(
              config: <Breakpoint, SlotLayoutConfig>{
                Breakpoints.smallAndUp: SlotLayout.from(
                  key: const Key('Body Small'),
                  builder: (BuildContext ctx) => widget.child,
                ),
              },
            ),
            bottomNavigation: !isDesktop
                ? SlotLayout(
                    config: <Breakpoint, SlotLayoutConfig>{
                      //In desktop, we have ability to adjust windows res,
                      // adjust to navbar as primary to smaller views.
                      Breakpoints.smallAndUp: SlotLayout.from(
                        key: const Key('Bottom Navigation Small'),
                        inAnimation: AdaptiveScaffold.bottomToTop,
                        outAnimation: AdaptiveScaffold.topToBottom,
                        builder: (BuildContext ctx) => BottomNavigationBar(
                          key: Keys.mainNav,
                          showSelectedLabels: false,
                          showUnselectedLabels: false,
                          currentIndex: bottomBarIdx,
                          onTap: (index) =>
                              context.go(bottomBarNav[index].initialLocation),
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
    );
  }

  Future<void> handleBugReport() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    // rage shake disallows dot in filename
    String timestamp = Jiffy.now().toUtc().format();
    final imagePath = await screenshotController.captureAndSave(
      appDocDir.path,
      fileName: 'screenshot_$timestamp.png',
    );
    if (imagePath != null && context.mounted) {
      await context.pushNamed(
        Routes.bugReport.name,
        extra: {'screenshot': imagePath},
      );
    } else if (context.mounted) {
      await context.push(Routes.bugReport.name);
    }
  }
}
