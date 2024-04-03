import 'package:acter/common/models/profile_data.dart';
import 'package:acter/features/activities/providers/notifiers/invitation_list_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';

final invitationListProvider =
    NotifierProvider<InvitationListNotifier, List<Invitation>>(
  () => InvitationListNotifier(),
);

final invitationUserProfileProvider = FutureProvider.autoDispose
    .family<ProfileData?, Invitation>((ref, invitation) async {
  UserProfile? user = invitation.senderProfile();
  if (user == null) {
    return null;
  }

  final displayName = user.getDisplayName();
  final avatar = await user.getAvatar(null);
  return ProfileData(displayName, avatar.data());
});
