import 'dart:core';

import 'package:acter/common/models/profile_data.dart';
import 'package:acter/features/home/states/client_state.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountProfile {
  final Account account;
  final ProfileData profile;
  const AccountProfile(this.account, this.profile);
}

Future<ProfileData> getProfileData(Account account) async {
  // FIXME: how to get informed about updates!?!
  final name = await account.displayName();
  final avatar = await account.avatar();
  return ProfileData(name, avatar);
}

final accountProvider = FutureProvider((ref) async {
  final client = ref.watch(clientProvider)!;
  return client.account();
});

final accountProfileProvider = FutureProvider((ref) async {
  final account = ref.watch(accountProvider).requireValue;
  final profile = await getProfileData(account);
  return AccountProfile(account, profile);
});
