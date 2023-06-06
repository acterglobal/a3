import 'package:acter/features/chat/models/invitation_profile.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Invitation, UserProfile, DispName;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final invitationProfileProvider =
    FutureProvider.family<InvitationProfile, Invitation>(
        (ref, invitation) async {
  UserProfile profile = invitation.getSenderProfile();
  DispName dispName = await profile.getDisplayName();
  String? roomName = await invitation.roomName();
  String roomId = invitation.roomId().toString();
  final avatar = await profile.getAvatar();
  return InvitationProfile(dispName.text(), avatar, roomName, roomId);
});
