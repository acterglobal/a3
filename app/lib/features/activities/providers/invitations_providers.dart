import 'package:acter/features/activities/providers/notifiers/invitation_list_notifier.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';

final invitationListProvider =
    NotifierProvider<InvitationListNotifier, List<Invitation>>(
  () => InvitationListNotifier(),
);

final invitationUserProfileProvider = FutureProvider.autoDispose
    .family<AvatarInfo?, Invitation>((ref, invitation) async {
  UserProfile? user = invitation.senderProfile();
  if (user == null) {
    return null;
  }
  final userId = user.userId().toString();
  final displayName = user.getDisplayName();
  final fallback = AvatarInfo(uniqueId: userId, displayName: displayName);
  final avatar = await user.getAvatar(null);

  if (!user.hasAvatar() || avatar.data() == null) {
    return fallback;
  }
  final data = MemoryImage(avatar.data()!.asTypedList());

  return AvatarInfo(
    uniqueId: userId,
    displayName: displayName,
    avatar: data,
  );
});
