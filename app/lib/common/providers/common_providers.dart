import 'dart:async';

import 'package:acter/common/models/profile_data.dart';
import 'package:acter/common/providers/notifiers/notification_settings_notifier.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::common::providers');

// Loading Providers
final loadingProvider = StateProvider<bool>((ref) => false);

// Account Avatar Info Providers
class AccountWithAvatarInfo {
  final Account account;
  final AvatarInfo avatarInfo;

  const AccountWithAvatarInfo(this.account, this.avatarInfo);
}

final genericUpdatesStream =
    StreamProvider.family<int, String>((ref, key) async* {
  final client = ref.watch(alwaysClientProvider);
  int counter = 0; // to ensure the value updates

  // ignore: unused_local_variable
  await for (final value in client.subscribeStream(key)) {
    yield counter;
    counter += 1;
  }
});

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

final accountWithAvatarInfoProvider =
    FutureProvider.autoDispose<AccountWithAvatarInfo>((ref) async {
  final sdk = await ref.watch(sdkProvider.future);
  final account = ref.watch(accountProvider);
  final thumbSize = sdk.api.newThumbSize(48, 48);
  final userId = account.userId().toString();

  final avatar = await account.avatar(thumbSize);
  final fallback = AvatarInfo(uniqueId: userId);
  if (avatar.data() == null) {
    return AccountWithAvatarInfo(account, fallback);
  }
  final avatarInfo = ref.watch(accountAvatarInfoProvider);
  return AccountWithAvatarInfo(account, avatarInfo);
});

final accountAvatarInfoProvider = StateProvider.autoDispose<AvatarInfo>((ref) {
  final account = ref.watch(accountProvider);
  final userId = account.userId().toString();

  final displayName = ref.watch(accountDisplayNameProvider).valueOrNull;
  final avatar = ref.watch(_accountAvatarProvider).valueOrNull;
  final fallback = AvatarInfo(
    uniqueId: userId,
    displayName: displayName,
  );

  if (avatar == null) {
    return fallback;
  }

  return AvatarInfo(
    uniqueId: userId,
    displayName: displayName,
    avatar: avatar,
  );
});

/// Caching the name of each Room
final accountDisplayNameProvider =
    FutureProvider.autoDispose<String?>((ref) async {
  final account = ref.watch(accountProvider);
  return (await account.displayName()).text();
});

final _accountAvatarProvider =
    FutureProvider.autoDispose<MemoryImage?>((ref) async {
  final sdk = await ref.watch(sdkProvider.future);
  final account = ref.watch(accountProvider);
  final thumbSize = sdk.api.newThumbSize(48, 48);
  final avatar = await account.avatar(thumbSize);
  if (avatar.data() != null) {
    return MemoryImage(avatar.data()!.asTypedList());
  }
  return null;
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
  // ensure we are updated if the upgrade comes down the wire.
  ref.watch(genericUpdatesStream('global.acter.dev.three_pid'));
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

final canRedactProvider = FutureProvider.autoDispose.family<bool, dynamic>(
  ((ref, arg) async {
    try {
      return await arg.canRedact();
    } catch (error) {
      _log.severe('Fetching canRedact failed for $arg', error);
      return false;
    }
  }),
);
