import 'dart:async';

import 'package:acter/common/models/profile_data.dart';
import 'package:acter/common/providers/notifiers/notification_settings_notifier.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';

// Loading Providers
final loadingProvider = StateProvider<bool>((ref) => false);

// Account Profile Providers
class AccountProfile {
  final Account account;
  final ProfileData profile;

  const AccountProfile(this.account, this.profile);
}

Future<ProfileData> getProfileData(Account account) async {
  // FIXME: how to get informed about updates!?!
  final displayName = await account.displayName();
  final avatar = await account.avatar(null);
  return ProfileData(displayName.text(), avatar.data());
}

final myUserIdStrProvider = StateProvider(
  (ref) => ref.watch(
    alwaysClientProvider.select((client) => client.userId().toString()),
  ),
);

final accountProvider = StateProvider(
  (ref) => ref.watch(
    alwaysClientProvider.select((client) => client.account()),
  ),
);

final accountProfileProvider = FutureProvider((ref) async {
  final account = ref.watch(accountProvider);
  final profile = await getProfileData(account);
  return AccountProfile(account, profile);
});

final notificationSettingsProvider = AsyncNotifierProvider<
    AsyncNotificationSettingsNotifier,
    NotificationSettings>(() => AsyncNotificationSettingsNotifier());

final appContentNotificationSetting =
    FutureProvider.family<bool, String>((ref, appKey) async {
  final notificationsSettings =
      await ref.watch(notificationSettingsProvider.future);
  return await notificationsSettings.globalContentSetting(appKey);
});

// Email addresses that registered by user
class EmailAddresses {
  final List<String> confirmed;
  final List<String> unconfirmed;

  const EmailAddresses(this.confirmed, this.unconfirmed);
}

final emailAddressesProvider = FutureProvider((ref) async {
  final client = ref.watch(alwaysClientProvider);
  final threePidManager = client.threePidManager();
  final confirmed =
      asDartStringList(await threePidManager.confirmedEmailAddresses());
  final requested =
      asDartStringList(await threePidManager.requestedEmailAddresses());
  final List<String> unconfirmed = [];
  for (var i = 0; i < requested.length; i++) {
    if (!confirmed.contains(requested[i])) {
      unconfirmed.add(requested[i]);
    }
  }
  return EmailAddresses(confirmed, unconfirmed);
});
