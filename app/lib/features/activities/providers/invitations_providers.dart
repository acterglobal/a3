import 'package:acter/common/models/invitation_profile.dart';
import 'package:acter/features/activities/providers/notifiers/invitation_list_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::common::invitations');

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
    displayName = profile.getDisplayName();
    avatar = (await profile.getAvatar(null)).data();
  } catch (e, s) {
    _log.severe('failed to load profile', e, s);
  }
  String? roomName = await invitation.roomName();
  String roomId = invitation.roomId().toString();
  return InvitationProfile(displayName, avatar, roomName, roomId);
});
