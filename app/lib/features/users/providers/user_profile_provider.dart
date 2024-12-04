import 'dart:typed_data';

import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';

final globalUserProfileProvider =
    FutureProvider.family<UserProfile?, String>((ref, userId) async {
  final client = ref.watch(alwaysClientProvider);
  return (await client.searchUsers(userId)).toList().firstOrNull;
});

final userDisplayNameProvider = FutureProvider.autoDispose
    .family<String?, UserProfile>((ref, profile) async {
  return profile.displayName();
});

/// Caching the MemoryImage of each room
final _userAvatarProvider = FutureProvider.autoDispose
    .family<MemoryImage?, UserProfile>((ref, profile) async {
  final sdk = await ref.watch(sdkProvider.future);

  final thumbsize = sdk.api.newThumbSize(48, 48);
  final avatar = await profile.getAvatar(thumbsize);
  return avatar
      .data()
      .map((data) => MemoryImage(Uint8List.fromList(data.asTypedList())));
});

final userAvatarInfoProvider =
    Provider.autoDispose.family<AvatarInfo, UserProfile>((ref, profile) {
  final displayName = ref.watch(userDisplayNameProvider(profile)).valueOrNull;
  final avatarData = ref.watch(_userAvatarProvider(profile)).valueOrNull;

  return AvatarInfo(
    uniqueId: profile.userId().toString(),
    displayName: displayName,
    avatar: avatarData,
  );
});
