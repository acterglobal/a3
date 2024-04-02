import 'package:acter/common/models/profile_data.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/activities/providers/invitations_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Invitation, UserProfile;
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

class InvitationCard extends ConsumerWidget {
  final Invitation invitation;
  final Color avatarColor;

  const InvitationCard({
    super.key,
    required this.invitation,
    required this.avatarColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitationProfile = ref.watch(invitationProfileProvider(invitation));
    final roomId = invitation.roomIdStr();
    final userId = invitation.senderIdStr();
    return invitationProfile.when(
      data: (data) {
        final inviterProfile = data.$2;
        final room = data.$1;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: ActerAvatar(
                  mode: DisplayMode.Space,
                  avatarInfo: AvatarInfo(
                    uniqueId: roomId,
                    displayName: room.displayName,
                    avatar: room.getAvatarImage(),
                  ),
                  size: 48,
                ),
                title: Text(room.displayName ?? roomId),
                subtitle: Row(
                  children: [
                    Text(L10n.of(context).invitationText2),
                    inviter(
                      context,
                      inviterProfile,
                      userId,
                    ),
                  ],
                ),
              ),
              Divider(
                color: Theme.of(context).colorScheme.neutral6,
                indent: 5,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    // Reject Invitation Button
                    OutlinedButton(
                      onPressed: () async => await invitation.reject(),
                      child: Text(L10n.of(context).decline),
                    ),
                    const SizedBox(width: 15),
                    // Accept Invitation Button
                    ElevatedButton(
                      onPressed: () => _onTapAcceptInvite(ref, context, roomId),
                      child: Text(L10n.of(context).accept),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      error: (error, stackTrace) => Card(
        child: ListTile(
          title: Text('Error loading invitation: $error'),
        ),
      ),
      loading: () => Skeletonizer(
        child: Card(
          child: ListTile(title: Text(roomId)),
        ),
      ),
    );
  }

  Widget inviter(BuildContext context, ProfileData? profile, String userId) {
    if (profile == null) {
      return Chip(
        visualDensity: VisualDensity.compact,
        avatar: ActerAvatar(
          mode: DisplayMode.DM,
          avatarInfo: AvatarInfo(
            uniqueId: userId,
          ),
          size: 24,
        ),
        label: Text(userId),
      );
    }
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: ActerAvatar(
        mode: DisplayMode.DM,
        avatarInfo: AvatarInfo(
          uniqueId: userId,
          displayName: profile.displayName,
          avatar: profile.getAvatarImage(),
        ),
        size: 24,
      ),
      label: Text(profile.displayName ?? userId),
    );
  }

  // method for post-process invitation accept
  void _onTapAcceptInvite(
    WidgetRef ref,
    BuildContext ctx,
    String roomId,
  ) async {
    EasyLoading.show(status: 'Joining', dismissOnTap: false);
    bool res = await invitation.accept();
    if (!res) {
      EasyLoading.dismiss();
      EasyLoading.showError('Failed to join');
      return;
    }
    EasyLoading.dismiss();
    EasyLoading.showSuccess('Joined');
  }
}
