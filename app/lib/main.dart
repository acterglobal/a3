import 'dart:async';

import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/config/desktop.dart';
import 'package:acter/config/env.g.dart';
import 'package:acter/config/notifications/init.dart';
import 'package:acter/common/providers/app_state_provider.dart';
import 'package:acter/common/themes/acter_theme.dart';
import 'package:acter/common/tutorial_dialogs/bottom_navigation_tutorials/bottom_navigation_tutorials.dart';
import 'package:acter/common/tutorial_dialogs/space_overview_tutorials/create_or_join_space_tutorials.dart';
import 'package:acter/common/tutorial_dialogs/space_overview_tutorials/space_overview_tutorials.dart';
import 'package:acter/common/utils/language.dart';
import 'package:acter/common/utils/logging.dart';
import 'package:acter/common/utils/main.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/cli/main.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter/router/router.dart';
import 'package:flutter/cupertino.dart';
import 'package:acter/config/setup.dart';
import 'package:acter_trigger_auto_complete/acter_trigger_autocomplete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_simple_calculator/flutter_simple_calculator.dart';
import 'package:secure_application/secure_application.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:video_player_media_kit/video_player_media_kit.dart';

void main(List<String> args) async {
  configSetup();
  if (args.isNotEmpty) {
    await cliMain(args);
  } else {
    await _startAppInner(makeApp(), true);
  }
}

Widget makeApp() {
  return const ProviderScope(child: Acter());
}

Future<void> startAppForTesting(Widget app) async {
  // make sure our test isn't distracted by the onboarding wizzards
  setCreateOrJoinSpaceTutorialAsViewed();
  setBottomNavigationTutorialsAsViewed();
  setSpaceOverviewTutorialsAsViewed();
  return await _startAppInner(app, false);
}

Future<void> _startAppInner(Widget app, bool withSentry) async {
  WidgetsFlutterBinding.ensureInitialized();
  VideoPlayerMediaKit.ensureInitialized(
    android: true,
    iOS: true,
    macOS: true,
    windows: true,
    linux: true,
  );
  await initLogging();
  final initialLocationFromNotification = await initializeNotifications();

  if (isDesktop) {
    app = DesktopSupport(child: app);
  }

  if (initialLocationFromNotification != null) {
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      // push after the next render to ensure we still have the "initial" location
      goRouter.push(initialLocationFromNotification);
    });
  }

  if (withSentry) {
    await SentryFlutter.init(
      (options) {
        // we use the dart-define default env for the default stuff.
        options.dsn = Env.sentryDsn;
        options.environment = Env.sentryEnvironment;
        options.release = Env.sentryRelease;

        // allows us to check whether the user has activated tracing
        // and prevent reporting otherwise.
        options.beforeSend = sentryBeforeSend;
      },
      appRunner: () => runApp(app),
    );
  } else {
    runApp(app);
  }
}

class Acter extends ConsumerStatefulWidget {
  const Acter({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ActerState();
}

class _ActerState extends ConsumerState<Acter> with WidgetsBindingObserver {
  final secureApplicationController = SecureApplicationController(
    SecureApplicationState(
      locked: true,
      secured: true,
    ),
  );
  @override
  void initState() {
    super.initState();
    initLanguage(ref);
    WidgetsBinding.instance.addObserver(this);

    // WidgetsBinding.instance?.addPostFrameCallback((_) => localAuthenticate());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState newState) {
    ref.read(appStateProvider.notifier).update((state) => newState);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Widget appBuilder(BuildContext context, Widget? child) {
    final obfuscateApp =
        ref.watch(featuresProvider).isActive(LabsFeature.obfuscatedApp);

    // EasyLoading Wrapper
    final easyLoadingBuilder = EasyLoading.init();
    // all toast msgs will appear at bottom
    EasyLoading.instance.toastPosition = EasyLoadingToastPosition.bottom;
    final inner = easyLoadingBuilder(context, child);

    if (obfuscateApp || true) {
      print("putting into secure app");
      return SecureApplication(
        nativeRemoveDelay: 800,
        secureApplicationController: secureApplicationController,
        child: SecureGate(
          opacity: 1,
          lockedBuilder: (context, secureNotifier) => SimpleCalculator(
            onChanged: (key, value, expression) {
              print("key $key, value $value, expression: $expression");
              if (value.toString() == '1984.0') {
                print('unlocking');
                secureNotifier!.unlock();
              }
            },
          ),
          child: inner,
        ),
      );
    }

    return inner;
  }

  Future<bool?> askValidation(BuildContext context) async {
    final context = rootNavKey.currentState!.overlay!.context;
    print("asking to validate!");
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text('Unlock app content'),
          content: Text(
              'Do you wan to unlock the application content? Clicking no will secure the app'),
          actions: <Widget>[
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            CupertinoDialogAction(
              child: Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);

    return Portal(
      child: MaterialApp.router(
        routerConfig: goRouter,
        theme: ActerTheme.theme,
        title: 'Acter',
        builder: appBuilder,
        locale: Locale(language),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        // MaterialApp contains our top-level Navigator
      ),
    );
  }
}
