import 'dart:async';

import 'package:acter/common/models/profile_data.dart';
import 'package:acter/common/providers/notifiers/network_notifier.dart';
import 'package:acter/common/providers/notifiers/chat_notifier.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
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
  final Account account;
  final ProfileData profile;

  const AccountProfile(this.account, this.profile);
}

Future<ProfileData> getProfileData(Account account) async {
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

/// Provider the profile data of a the given space, keeps up to date with underlying client
final convoProvider =
    AsyncNotifierProvider.family<AsyncConvoNotifier, Convo?, Convo>(
  () => AsyncConvoNotifier(),
);

// Chat Providers
final chatProfileDataProvider =
    FutureProvider.family<ProfileData, Convo>((ref, convo) async {
  final chat = await ref.watch(convoProvider(convo).future);
  if (chat == null) {
    throw 'Chat not accessible';
  }
  // FIXME: how to get informed about updates!?!
  final profile = chat.getProfile();
  final displayName = await profile.getDisplayName();
  if (!profile.hasAvatar()) {
    return ProfileData(displayName.text(), null);
  }
  final avatar = await profile.getThumbnail(48, 48);
  return ProfileData(displayName.text(), avatar.data());
});

final latestMessageProvider =
    FutureProvider.autoDispose.family<RoomMessage?, Convo>((ref, convo) async {
  final chat = await ref.watch(convoProvider(convo).future);
  if (chat == null) {
    throw 'Chat not accessible';
  }
  return chat.latestMessage();
});

final chatProfileDataProviderById =
    FutureProvider.family<ProfileData, String>((ref, roomId) async {
  final chat = await ref.watch(chatProvider(roomId).future);
  return (await ref.watch(chatProfileDataProvider(chat).future));
});

final chatsProvider = FutureProvider<List<Convo>>((ref) async {
  final client = ref.watch(clientProvider)!;
  // FIXME: how to get informed about updates!?!
  final chats = await client.convos();
  return chats.toList();
});

final chatProvider =
    FutureProvider.family<Convo, String>((ref, roomIdOrAlias) async {
  final client = ref.watch(clientProvider)!;
  // FIXME: fallback to fetching a public data, if not found
  return await client.convo(roomIdOrAlias);
});

final chatMembersProvider =
    FutureProvider.family<List<Member>, String>((ref, roomIdOrAlias) async {
  final chat = await ref.watch(chatProvider(roomIdOrAlias).future);
  final members = await chat.activeMembers();
  return members.toList();
});

final relatedChatsProvider = FutureProvider.autoDispose
    .family<List<Convo>, String>((ref, spaceId) async {
  return (await ref.watch(spaceRelationsOverviewProvider(spaceId).future))
      .knownChats;
});

class SelectedChatIdNotifier extends Notifier<String?> {
  @override
  String? build() {
    return null;
  }

  void select(String? input) {
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      state = input;
    });
  }
}

final selectedChatIdProvider =
    NotifierProvider<SelectedChatIdNotifier, String?>(
        () => SelectedChatIdNotifier());

final currentConvoProvider = FutureProvider<Convo?>((ref) async {
  final roomId = ref.watch(selectedChatIdProvider);
  if (roomId == null) {
    throw 'No chat selected';
  }
  return await ref.watch(chatProvider(roomId).future);
});

// Member Providers
// TODO: improve this to be reusable for space and chat members alike.
final memberProfileByIdProvider =
    FutureProvider.family<ProfileData, String>((ref, userId) async {
  final member = await ref.watch(memberProvider(userId).future);
  if (member == null) {
    throw 'Member not found';
  }
  return await ref.watch(memberProfileProvider(member).future);
});

final memberProfileProvider =
    FutureProvider.family<ProfileData, Member>((ref, member) async {
  UserProfile profile = member.getProfile();
  OptionString displayName = await profile.getDisplayName();
  final avatar = await profile.getThumbnail(62, 60);
  return ProfileData(displayName.text(), avatar.data());
});

final memberProvider =
    FutureProvider.family<Member?, String>((ref, userId) async {
  final convo = await ref.watch(currentConvoProvider.future);
  if (convo == null) {
    throw 'No chat selected';
  }
  return await convo.getMember(userId);
});
