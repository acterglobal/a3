import 'package:acter/features/chat/models/invitation_profile.dart';
import 'package:acter/features/activities/providers/notifiers/invitation_list_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

final invitationListProvider =
    NotifierProvider<InvitationListNotifier, List<Invitation>>(
  () => InvitationListNotifier(),
);

final invitationProfileProvider =
    FutureProvider.family<InvitationProfile, Invitation>(
        (ref, invitation) async {
  String? displayName;
  FfiBufferUint8? avatar;
  try {
    UserProfile profile = await invitation.getSenderProfile();
    displayName = (await profile.getDisplayName()).text();
    avatar = (await profile.getAvatar()).data();
  } catch (e) {
    debugPrint('failed to load profile: $e');
  }
  String? roomName = await invitation.roomName();
  String roomId = invitation.roomId().toString();
  return InvitationProfile(displayName, avatar, roomName, roomId);
});
