import 'dart:io';

import 'package:appcheck/appcheck.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ExternalApps { whatsApp, telegram, signal }

final isAppInstalledProvider = FutureProvider.family<bool, ExternalApps>(
  (ref, externalApp) async {
    return switch (externalApp) {
      ExternalApps.whatsApp => await checkAppAvailability(
          Platform.isAndroid ? 'com.whatsapp' : 'whatsapp://',
        ),
      ExternalApps.telegram => await checkAppAvailability(
          Platform.isAndroid ? 'org.telegram.messenger' : 'tg://',
        ),
      ExternalApps.signal => await checkAppAvailability(
          Platform.isAndroid ? 'org.thoughtcrime.securesms' : 'sgnl://',
        ),
    };
  }, // this means we are running
);

Future<bool> checkAppAvailability(String package) async {
  try {
    final app = await AppCheck().checkAvailability(package);
    return app != null;
  } catch (e) {
    return false;
  }
}
