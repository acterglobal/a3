import 'dart:io';

import 'package:appcheck/appcheck.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ExternalApps { whatsApp, whatsBusiness, telegram, signal }

final isAppInstalledProvider = FutureProvider.family<bool, ExternalApps>(
  (ref, externalApp) async {
    final appCheck = AppCheck();
    return switch (externalApp) {
      ExternalApps.whatsApp => await appCheck.isAppInstalled(
        Platform.isAndroid ? 'com.whatsapp' : 'whatsapp://',
      ),
      ExternalApps.whatsBusiness => await appCheck.isAppInstalled(
        Platform.isAndroid ? 'com.whatsapp.w4b' : 'whatsapp://',
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
