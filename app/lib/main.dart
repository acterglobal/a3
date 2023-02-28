import 'dart:async';

import 'package:effektio/common/themes/app_theme.dart';
import 'package:effektio/features/home/pages/home_page.dart';
import 'package:effektio/l10n/l10n.dart';
import 'package:effektio/features/onboarding/pages/login_page.dart';
import 'package:effektio/features/onboarding/pages/sign_up_page.dart';
import 'package:effektio/features/gallery/pages/gallery_page.dart';
import 'package:effektio/features/profile/pages/social_profile_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:themed/themed.dart';

void main() async {
  await startApp();
}

Future<void> startApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('google_fonts/LICENSE.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
  runApp(const ProviderScope(child: Effektio()));
}

class Effektio extends StatelessWidget {
  const Effektio({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugInvertOversizedImages = true; // detect non-optimized images
    return Portal(
      child: Themed(
        child: OverlaySupport.global(
          child: GetMaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.theme,
            title: 'Effektio',
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: ApplicationLocalizations.supportedLocales,
            // MaterialApp contains our top-level Navigator
            initialRoute: '/',
            routes: <String, WidgetBuilder>{
              '/': (BuildContext context) => const HomePage(),
              '/login': (BuildContext context) => const LoginPage(),
              '/profile': (BuildContext context) => const SocialProfilePage(),
              '/signup': (BuildContext context) => const SignupPage(),
              '/gallery': (BuildContext context) => const GalleryPage(),
            },
          ),
        ),
      ),
    );
  }
}
