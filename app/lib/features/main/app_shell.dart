import 'package:acter/common/providers/app_state_provider.dart';
import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/tutorial_dialogs/bottom_navigation_tutorials/bottom_navigation_tutorials.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/device.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/config/notifications/init.dart';
import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter/features/auth/pages/logged_out_screen.dart';
import 'package:acter/features/bug_report/actions/open_bug_report.dart';
import 'package:acter/features/bug_report/providers/bug_report_providers.dart';
import 'package:acter/features/calendar_sync/calendar_sync.dart';
import 'package:acter/features/cross_signing/widgets/cross_signing.dart';
import 'package:acter/features/deep_linking/actions/handle_deep_link_uri.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/home/widgets/sidebar_widget.dart';
import 'package:acter/features/main/providers/main_providers.dart';
import 'package:acter/features/main/widgets/bottom_navigation_widget.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter/features/notifications/providers/notification_settings_providers.dart';
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
    _initShake();
    _initDeepLinking();
    // initalize main providers
    _initProviders();

    // these want to be sure to execute in order
    await _initNotifications();
    // calendar sync
    await _initCalendarSync();
  }

  Future<void> _initProviders() async {
    // we read a few providers immediately at start up to ensure
    // the content is being fetched and cached
    ref.read(spacesProvider);
    ref.read(chatsProvider);
    ref.read(newsListProvider(null));
    ref.read(hasActivitiesProvider);
  }

  Future<void> _initShake() async {
    // shake is possible in only actual mobile devices
    if (isBugReportingEnabled && await isRealPhone()) {
      detector = ShakeDetector.autoStart(
        shakeThresholdGravity: 30.0,
        onShake: () {
          if (ref.read(isAppInForeground)) {
            openBugReport(context);
          }
        },
      );
    }
  }

  Future<void> _initNotifications() async {
    final client = await ref.read(clientProvider.future);
    if (client != null) {
      _initPushForClient(client);
    }
    ref.listenManual(clientProvider, (previous, next) {
      final newClient = next.valueOrNull;
      if (newClient != null) {
        _initPushForClient(newClient);
      }
    });
  }

  Future<void> _initCalendarSync() async {
    final client = await ref.read(clientProvider.future);
    if (client != null) {
      // calendar sync only works if we have a client
      await initCalendarSync();
    }
    ref.listenManual(clientProvider, (previous, next) {
      final newClient = next.valueOrNull;
      if (newClient != null) {
        initCalendarSync();
      }
    });
  }

  Future<void> _initPushForClient(Client client) async {
    final pushActive = await ref.read(isPushNotificationsActiveProvider.future);
    if (!pushActive) return;
    _log.info('Attempting to ask for push notifications');
    setupPushNotifications(client);
  }

  Future<void> _initDeepLinking() async {
    appLinks.uriLinkStream.listen((Uri uri) async {
      debugPrint('Received Deep Link URI: $uri');
      if (mounted) {
        await handleDeepLinkUri(context: context, ref: ref, uri: uri);
      } else {
        debugPrint('Not mounted');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // get platform of context.
    if (ref.watch(clientProvider).valueOrNull == null) {
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
          context.goNamed(Routes.search.name);
        },
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK): () {
          context.goNamed(Routes.search.name);
        },
      },
      child: KeyboardDismissOnTap(
        // close keyboard if clicking somewhere else
        child: Scaffold(
          body: Screenshot(
            controller: screenshotController,
            child: Column(
              children: [
                CrossSigning(),
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

  SlotLayout bottomNavigationLayout() {
    return SlotLayout(
      config: <Breakpoint, SlotLayoutConfig>{
        Breakpoints.small: SlotLayout.from(
          key: Keys.mainNav,
          inAnimation: AdaptiveScaffold.bottomToTop,
          outAnimation: AdaptiveScaffold.topToBottom,
          builder: (context) =>
              BottomNavigationWidget(navigationShell: widget.navigationShell),
        ),
        Breakpoints.medium: SlotLayout.from(
          key: Keys.mainNav,
          inAnimation: AdaptiveScaffold.bottomToTop,
          outAnimation: AdaptiveScaffold.topToBottom,
          builder: (context) =>
              BottomNavigationWidget(navigationShell: widget.navigationShell),
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
