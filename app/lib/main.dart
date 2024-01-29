import 'dart:async';

import 'package:acter/common/notifications/notifications.dart';
import 'package:acter/common/themes/acter_theme.dart';
import 'package:acter/common/utils/logging.dart';
import 'package:acter/features/cli/main.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:acter/router/providers/router_providers.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:video_player_media_kit/video_player_media_kit.dart';

void main(List<String> args) async {
  if (args.isNotEmpty) {
    await cliMain(args);
  } else {
    await startAppInner(makeApp());
  }
}

Widget makeApp() {
  return const ProviderScope(child: Acter());
}

Future<void> startAppInner(Widget app) async {
  WidgetsFlutterBinding.ensureInitialized();
  VideoPlayerMediaKit.ensureInitialized(
    android: true,
    iOS: true,
    macOS: true,
    windows: true,
    linux: true,
  );
  await initializeNotifications();
  await initLogging();
  runApp(app);
}

class Acter extends ConsumerStatefulWidget {
  const Acter({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ActerState();
}

class _ActerState extends ConsumerState<Acter> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final appRouter = ref.watch(goRouterProvider);
    return Portal(
      child: OverlaySupport.global(
        child: MaterialApp.router(
          routerConfig: appRouter,
          theme: ActerTheme.theme,
          title: 'Acter',
          builder: EasyLoading.init(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            AppFlowyEditorLocalizations.delegate,
          ],
          supportedLocales: ApplicationLocalizations.supportedLocales,
          // MaterialApp contains our top-level Navigator
        ),
      ),
    );
  }
}
