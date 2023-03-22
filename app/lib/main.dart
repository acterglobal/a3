import 'dart:async';
import 'dart:io';

import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:themed/themed.dart';
import 'package:window_size/window_size.dart';

import 'package:acter/routing.dart';

void main() async {
  await startApp();
}

Future<void> startFreshTestApp(String key) async {
  await ActerSdk.resetSessionsAndClients(key);
  await startApp();
}

Future<void> startApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  if (isDesktop) {
    setWindowTitle('Acter');
  }
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('google_fonts/LICENSE.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
  runApp(const ProviderScope(child: Acter()));
}

class Acter extends StatelessWidget {
  const Acter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Portal(
      child: Themed(
        child: OverlaySupport.global(
          child: MaterialApp.router(
            routerConfig: router,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.theme,
            title: 'Acter',
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
      ),
    );
  }
}
