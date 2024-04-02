import 'package:acter/common/models/profile_data.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/activities/providers/notifiers/invitation_list_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::common::invitations');

final invitationListProvider =
    NotifierProvider<InvitationListNotifier, List<Invitation>>(
  () => InvitationListNotifier(),
);

final invitationProfileProvider = FutureProvider.autoDispose.family<
    (
      ProfileData,
      ProfileData?,
    ),
    Invitation>((ref, invitation) async {
  final roomProfile =
      await ref.watch(roomProfileDataProvider(invitation.roomIdStr()).future);
  UserProfile? user = invitation.senderProfile();
  if (user == null) {
    return (roomProfile, null);
  }

  final displayName = user.getDisplayName();
  final avatar = await user.getAvatar(null);
  return (roomProfile, ProfileData(displayName, avatar.data()));
});
