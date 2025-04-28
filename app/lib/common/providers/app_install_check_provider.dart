import 'dart:io';

import 'package:appcheck/appcheck.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ExternalApps {
  whatsApp,
  whatsBusiness,
  telegram,
  signal,
  onePassword,
  bitwarden,
  keeper,
  lastPass,
  enpass,
  protonPass,
}

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
      ExternalApps.onePassword => await appCheck.isAppInstalled(
        Platform.isAndroid ? 'com.onepassword.android' : 'onepassword://',
      ),
      ExternalApps.bitwarden => await appCheck.isAppInstalled(
        Platform.isAndroid ? 'com.x8bit.bitwarden' : 'bitwarden://',
      ),
      ExternalApps.keeper =>
        Platform.isIOS ? appCheck.isAppInstalled('keeper://') : false,
      ExternalApps.lastPass =>
        Platform.isIOS ? await appCheck.isAppInstalled('lastpass://') : false,
      ExternalApps.enpass =>
        Platform.isIOS ? await appCheck.isAppInstalled('enpass://') : false,
      ExternalApps.protonPass =>
        Platform.isIOS ? await appCheck.isAppInstalled('protonpass://') : false,
    };
  }, // this means we are running
);
