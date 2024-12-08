import 'dart:io';

import 'package:appcheck/appcheck.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ExternalApps { whatsApp, telegram, signal }

final isAppInstalledProvider = FutureProvider.family<bool, ExternalApps>(
  (ref, externalApp) async {
    final appCheck = AppCheck();
    return switch (externalApp) {
      ExternalApps.whatsApp => await appCheck.isAppInstalled(
          Platform.isAndroid ? 'com.whatsapp' : 'whatsapp://',
        ),
      ExternalApps.telegram => await appCheck.isAppInstalled(
          Platform.isAndroid ? 'org.telegram.messenger' : 'tg://',
        ),
      ExternalApps.signal => await appCheck.isAppInstalled(
          Platform.isAndroid ? 'org.thoughtcrime.securesms' : 'sgnl://',
        ),
    };
  }, // this means we are running
);
