import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/activities/providers/invitations_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Invitation;
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
    final roomProfile =
        ref.watch(roomProfileDataProvider(invitation.roomIdStr()));

    final roomId = invitation.roomIdStr();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: roomProfile.maybeWhen(
              data: (room) => ActerAvatar(
                mode: DisplayMode.Space,
                avatarInfo: AvatarInfo(
                  uniqueId: roomId,
                  displayName: room.displayName,
                  avatar: room.getAvatarImage(),
                ),
                size: 48,
              ),
              orElse: () => ActerAvatar(
                mode: DisplayMode.Space,
                avatarInfo: AvatarInfo(
                  uniqueId: roomId,
                ),
                size: 48,
              ),
            ),
            title: roomProfile.when(
              data: (room) => Text(room.displayName ?? roomId),
              loading: () => Skeletonizer(child: Text(roomId)),
              error: (e, s) => Text('Error loading $roomId: $e'),
            ),
            subtitle: Row(
              children: [
                Text(L10n.of(context).invitationText2),
                inviter(
                  context,
                  ref,
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
                  onPressed: _onTapDeclineInvite,
                  child: Text(L10n.of(context).decline),
                ),
                const SizedBox(width: 15),
                // Accept Invitation Button
                ElevatedButton(
                  onPressed: _onTapAcceptInvite,
                  child: Text(L10n.of(context).accept),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget inviter(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(invitationUserProfileProvider(invitation)).valueOrNull;
    final userId = invitation.senderIdStr();

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
  void _onTapAcceptInvite() async {
    EasyLoading.show(status: 'Joining', dismissOnTap: false);
    bool res = await invitation.accept();
    if (!res) {
      EasyLoading.showError('Failed to join');
      return;
    }
    EasyLoading.showSuccess('Joined');
  }

  void _onTapDeclineInvite() async {
    EasyLoading.show(status: 'Rejecting', dismissOnTap: false);
    bool res = await invitation.reject();
    if (!res) {
      EasyLoading.showError('Failed to reject');
      return;
    }
    EasyLoading.showSuccess('Rejected');
  }
}
