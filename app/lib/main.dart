import 'dart:async';
import 'dart:io';

import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/bug_report/pages/bug_report_page.dart';
import 'package:acter/features/gallery/pages/gallery_page.dart';
import 'package:acter/features/home/pages/home_page.dart';
import 'package:acter/features/onboarding/pages/login_page.dart';
import 'package:acter/features/onboarding/pages/sign_up_page.dart';
import 'package:acter/features/profile/pages/social_profile_page.dart';
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
          child: MaterialApp(
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
            initialRoute: '/',
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/':
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (ctx) => const HomePage(),
                  );
                case '/login':
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (ctx) => const LoginPage(),
                  );
                case '/profile':
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (ctx) => const SocialProfilePage(),
                  );
                case '/signup':
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (ctx) => const SignupPage(),
                  );
                case '/gallery':
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (ctx) => const GalleryPage(),
                  );
                case '/bug_report':
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (ctx) {
                      final map = settings.arguments as Map;
                      return BugReportPage(imagePath: map['screenshot']);
                    },
                  );
                default:
                  return null;
              }
            },
          ),
        ),
      ),
    );
  }
}
