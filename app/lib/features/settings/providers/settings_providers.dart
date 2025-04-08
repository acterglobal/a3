import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/notifiers/client_pref_notifier.dart';
import 'package:acter/common/utils/main.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/settings/providers/notifiers/locale_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final allowSentryReportingProvider = FutureProvider(
  (ref) => getCanReportToSentry(),
);

final allowMatomoAnalyticsProvider = FutureProvider(
  (ref) => getMatomoAnalyticsEnabled(),
);

final localeProvider = StateNotifierProvider<LocaleNotifier, String>(
  (ref) => LocaleNotifier(),
);

final ignoredUsersProvider = FutureProvider<List<UserId>>((ref) async {
  final account = await ref.watch(accountProvider.future);
  return (await account.ignoredUsers()).toList();
});

final pushersProvider = FutureProvider<List<Pusher>>((ref) async {
  final client = await ref.watch(alwaysClientProvider.future);
  return (await client.pushers()).toList();
});

final possibleEmailToAddForPushProvider = FutureProvider<List<String>>((
  ref,
) async {
  final emailAddress = await ref.watch(emailAddressesProvider.future);
  if (emailAddress.confirmed.isEmpty) {
    return [];
  }
  final pushers = await ref.watch(pushersProvider.future);
  if (pushers.isEmpty) {
    return emailAddress.confirmed;
  }

  var allowedEmails = emailAddress.confirmed;
  for (final p in pushers) {
    if (p.isEmailPusher()) {
      // for each pusher, remove the email from the potential list
      final addr = p.pushkey();
      if (allowedEmails.contains(addr)) {
        allowedEmails.remove(addr);
      }
    }
  }
  return allowedEmails;
});

enum OpenSystemLinkSetting {
  open,
  // prompt // ask what to do
  copy,
}

final openSystemLinkSettingsProvider =
    createMapPrefProvider<OpenSystemLinkSetting>(
      prefKey: 'openSystemLinkSettings',
      mapFrom:
          (v) => OpenSystemLinkSetting.values.firstWhere(
            (e) => e.toString() == v,
            orElse: () => OpenSystemLinkSetting.open,
          ),
      mapTo: (v) => v.toString(),
    );
