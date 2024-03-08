import 'package:acter/common/dialogs/logout_confirmation.dart';
import 'package:acter/common/providers/keyboard_visbility_provider.dart';
import 'package:acter/common/utils/device.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/activities/providers/notifications_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/home/widgets/home_body.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:dart_date/dart_date.dart';
import 'package:flutter/material.dart';
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

    // we also need to globally hook the notifications list so it can issue
    // desktop notifications if configured.
    // ignore: unused_local_variable
    final notifications = ref.watch(notificationsListProvider);
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

    return HomeBody(
      navigationShell: widget.navigationShell,
      keyboardVisible: keyboardVisibility.valueOrNull == true,
      hasFirstSynced: hasFirstSynced,
    );
  }
}
