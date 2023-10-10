import 'dart:async';

import 'package:acter/common/notifications/notifications.dart';
import 'package:acter/common/utils/logging.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/cli/main.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:acter/router/providers/router_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:overlay_support/overlay_support.dart';

void main(List<String> args) async {
  if (args.isNotEmpty) {
    await cliMain(args);
  } else {
    await startApp();
  }
}

Future<void> startFreshTestApp(String key) async {
  await ActerSdk.resetSessionsAndClients(key);
  await startAppInner();
}

Future<void> startApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await startAppInner();
}

Future<void> startAppInner() async {
  await initializeNotifications();
  await initLogging();
  runApp(const ProviderScope(child: Acter()));
}

class Acter extends ConsumerStatefulWidget {
  static const String name = 'Awesome Notifications - Example App';
  static const Color mainColor = Colors.deepPurple;

  const Acter({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ActerState();
}

class _ActerState extends ConsumerState<Acter> {
  @override
  void initState() {
    super.initState();
    setupNotificationsListeners();
  }

  @override
  Widget build(BuildContext context) {
    final appRouter = ref.watch(goRouterProvider);
    requestNotificationsPermissions();
    return Portal(
      child: OverlaySupport.global(
        child: MaterialApp.router(
          routerConfig: appRouter,
          theme: AppTheme.theme,
          title: 'Acter',
          builder: EasyLoading.init(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: ApplicationLocalizations.supportedLocales,
          // MaterialApp contains our top-level Navigator
        ),
      ),
    );
  }
}
