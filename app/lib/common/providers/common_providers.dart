import 'dart:typed_data';

import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::common::common_providers');

final eventTypeUpdatesStream =
    StreamProvider.family<int, String>((ref, key) async* {
  final client = ref.watch(alwaysClientProvider);
  int counter = 0; // to ensure the value updates

  // ignore: unused_local_variable
  await for (final value in client.subscribeEventTypeStream(key)) {
    yield counter;
    counter += 1;
  }
});

final myUserIdStrProvider = Provider(
  (ref) => ref.watch(
    alwaysClientProvider.select((client) => client.userId().toString()),
  ),
);

final accountProvider = Provider(
  (ref) => ref.watch(
    alwaysClientProvider.select((client) => client.account()),
  ),
);

final hasFirstSyncedProvider = Provider(
  (ref) => ref.watch(syncStateProvider.select((v) => !v.initialSync)),
);

final isGuestProvider =
    Provider((ref) => ref.watch(alwaysClientProvider).isGuest());

final deviceIdProvider = Provider(
  (ref) => ref.watch(
    alwaysClientProvider.select(
      (v) => v.deviceId().toString(),
    ),
  ),
);

/// Gives [AvatarInfo] object for user account. Stays up-to-date internally.
final accountAvatarInfoProvider = StateProvider.autoDispose<AvatarInfo>((ref) {
  final account = ref.watch(accountProvider);
  final userId = account.userId().toString();

  final displayName = ref.watch(accountDisplayNameProvider).valueOrNull;
  final avatar = ref.watch(_accountAvatarProvider).valueOrNull;

  return avatar.map(
        (data) => AvatarInfo(
          uniqueId: userId,
          displayName: displayName,
          avatar: data,
        ),
      ) ??
      AvatarInfo(
        uniqueId: userId,
        displayName: displayName,
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
  // Only call data() once as it will consume the value and any subsequent
  // call will come back with `null`.
  return avatar
      .data()
      .map((data) => MemoryImage(Uint8List.fromList(data.asTypedList())));
});

// Email addresses that registered by user
class EmailAddresses {
  final List<String> confirmed;
  final List<String> unconfirmed;

  const EmailAddresses(this.confirmed, this.unconfirmed);
}

final emailAddressesProvider = FutureProvider((ref) async {
  final account = ref.watch(accountProvider);
  // ensure we are updated if the upgrade comes down the wire.
  ref.watch(eventTypeUpdatesStream('global.acter.dev.three_pid'));
  final confirmed = asDartStringList(await account.confirmedEmailAddresses());
  final requested = asDartStringList(await account.requestedEmailAddresses());
  final unconfirmed =
      requested.where((email) => !confirmed.contains(email)).toList();
  return EmailAddresses(confirmed, unconfirmed);
});

final canRedactProvider = FutureProvider.autoDispose.family<bool, dynamic>(
  ((ref, arg) async {
    try {
      return await arg.canRedact();
    } catch (e, s) {
      _log.severe('Fetching canRedact failed for $arg', e, s);
      return false;
    }
  }),
);

final searchValueProvider = StateProvider.autoDispose<String>((ref) => '');
