import 'package:acter/common/controllers/client_controller.dart';
import 'package:acter/common/models/profile_data.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'dart:core';

final chatProfileDataProvider =
    FutureProvider.family<ProfileData, Conversation>((ref, chat) async {
  // FIXME: how to get informed about updates!?!
  final profile = await chat.getProfile();
  final name = profile.getDisplayName();
  final displayName = name ?? chat.getRoomId();
  if (!profile.hasAvatar()) {
    return ProfileData(displayName, null);
  }
  final avatar = await profile.getThumbnail(48, 48);
  return ProfileData(displayName, avatar);
});

final chatsProvider = FutureProvider<List<Conversation>>((ref) async {
  final client = ref.watch(clientProvider)!;
  // FIXME: how to get informed about updates!?!
  final chats = await client.conversations();
  return chats.toList();
});

final chatProvider =
    FutureProvider.family<Conversation, String>((ref, roomIdOrAlias) async {
  final client = ref.watch(clientProvider)!;
  // FIXME: fallback to fetching a public data, if not found
  return await client.conversation(roomIdOrAlias);
});

final chatMembersProvider =
    FutureProvider.family<List<Member>, String>((ref, roomIdOrAlias) async {
  final chat = ref.watch(chatProvider(roomIdOrAlias)).requireValue;
  final members = await chat.activeMembers();
  return members.toList();
});
