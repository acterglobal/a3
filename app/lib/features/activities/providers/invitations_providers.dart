import 'dart:typed_data';

import 'package:acter/features/activities/providers/notifiers/invitation_list_notifier.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:extension_nullable/extension_nullable.dart';
import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';

final invitationListProvider =
    NotifierProvider<InvitationListNotifier, List<Invitation>>(
  () => InvitationListNotifier(),
);

final invitationUserProfileProvider = FutureProvider.autoDispose
    .family<AvatarInfo?, Invitation>((ref, invitation) async {
  UserProfile? user = invitation.senderProfile();
  if (user == null) return null;
  final userId = user.userId().toString();
  final displayName = user.getDisplayName();
  final fallback = AvatarInfo(
    uniqueId: userId,
    displayName: displayName,
  );
  if (!user.hasAvatar()) return fallback;
  final avatar = await user.getAvatar(null);
  return avatar.data().map(
            (p0) => AvatarInfo(
              uniqueId: userId,
              displayName: displayName,
              avatar: MemoryImage(Uint8List.fromList(p0.asTypedList())),
            ),
          ) ??
      fallback;
});
