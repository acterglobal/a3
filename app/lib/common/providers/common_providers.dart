import 'dart:async';

import 'package:acter/common/models/profile_data.dart';
import 'package:acter/common/providers/notifiers/network_notifier.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Network/Connectivity Providers
final networkAwareProvider =
    StateNotifierProvider<NetworkStateNotifier, NetworkStatus>(
  (ref) => NetworkStateNotifier(),
);

// Loading Providers
final loadingProvider = StateProvider<bool>((ref) => false);

// Account Profile Providers
class AccountProfile {
  final ffi.Account account;
  final ProfileData profile;

  const AccountProfile(this.account, this.profile);
}

Future<ProfileData> getProfileData(ffi.Account account) async {
  // FIXME: how to get informed about updates!?!
  final displayName = await account.displayName();
  final avatar = await account.avatar();
  return ProfileData(displayName.text(), avatar.data());
}

final accountProvider = FutureProvider((ref) async {
  final client = ref.watch(clientProvider);
  if (client == null) {
    throw 'No Client found';
  }
  return client.account();
});

final accountProfileProvider = FutureProvider((ref) async {
  final account = await ref.watch(accountProvider.future);
  final profile = await getProfileData(account);
  return AccountProfile(account, profile);
});

// Chat Providers
final chatProfileDataProvider =
    FutureProvider.family<ProfileData, ffi.Convo>((ref, chat) async {
  // FIXME: how to get informed about updates!?!
  final profile = chat.getProfile();
  final displayName = await profile.getDisplayName();
  if (!profile.hasAvatar()) {
    return ProfileData(displayName.text(), null);
  }
  final avatar = await profile.getThumbnail(48, 48);
  return ProfileData(displayName.text(), avatar.data());
});

final chatsProvider = FutureProvider<List<ffi.Convo>>((ref) async {
  final client = ref.watch(clientProvider)!;
  // FIXME: how to get informed about updates!?!
  final chats = await client.convos();
  return chats.toList();
});

final chatProvider =
    FutureProvider.family<ffi.Convo, String>((ref, roomIdOrAlias) async {
  final client = ref.watch(clientProvider)!;
  // FIXME: fallback to fetching a public data, if not found
  return await client.convo(roomIdOrAlias);
});

final chatMembersProvider =
    FutureProvider.family<List<ffi.Member>, String>((ref, roomIdOrAlias) async {
  final chat = await ref.watch(chatProvider(roomIdOrAlias).future);
  final members = await chat.activeMembers();
  return members.toList();
});

final relatedChatsProvider = FutureProvider.autoDispose
    .family<List<ffi.Convo>, String>((ref, spaceId) async {
  return (await ref.watch(spaceRelationsOverviewProvider(spaceId).future))
      .knownChats;
});

// Member Providers
final memberProfileProvider =
    FutureProvider.family<ProfileData, ffi.Member>((ref, member) async {
  try {
    ffi.UserProfile profile = member.getProfile();
    ffi.OptionString displayName = await profile.getDisplayName();
    final avatar = await profile.getThumbnail(62, 60);
    return ProfileData(displayName.text(), avatar.data());
  } catch (e) {
    debugPrint('$e');
    return ProfileData('', null);
  }
});
