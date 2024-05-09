import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/app_theme.dart';

import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/activities/providers/invitations_providers.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Invitation;
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::activities::invitation_card');

class InvitationCard extends ConsumerWidget {
  final Invitation invitation;

  const InvitationCard({
    super.key,
    required this.invitation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          renderTile(context, ref),
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
                  onPressed: () => _onTapDeclineInvite(context),
                  child: Text(L10n.of(context).decline),
                ),
                const SizedBox(width: 15),
                // Accept Invitation Button
                ActerPrimaryActionButton(
                  onPressed: () => _onTapAcceptInvite(context),
                  child: Text(L10n.of(context).accept),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ListTile renderTile(BuildContext context, WidgetRef ref) {
    final isDM = invitation.isDm();
    if (isDM) {
      return renderDmChatTile(context, ref);
    }
    final room = invitation.room();
    if (room.isSpace()) {
      return renderSpaceTile(context, ref);
    }
    return renderGroupChatTile(context, ref);
  }

  ListTile renderSpaceTile(BuildContext context, WidgetRef ref) {
    final roomProfile =
        ref.watch(roomProfileDataProvider(invitation.roomIdStr()));

    final roomId = invitation.roomIdStr();
    return ListTile(
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
        error: (e, s) => Text(L10n.of(context).errorLoadingRoom(e, roomId)),
      ),
      subtitle: Wrap(
        children: [
          Text(L10n.of(context).invitationToSpace),
          inviter(
            context,
            ref,
          ),
        ],
      ),
    );
  }

  ListTile renderGroupChatTile(BuildContext context, WidgetRef ref) {
    final roomProfile =
        ref.watch(roomProfileDataProvider(invitation.roomIdStr()));

    final roomId = invitation.roomIdStr();
    return ListTile(
      leading: roomProfile.maybeWhen(
        data: (room) => ActerAvatar(
          mode: DisplayMode.GroupChat,
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
        error: (e, s) => Text(L10n.of(context).errorLoadingRoom(e, roomId)),
      ),
      subtitle: Wrap(
        children: [
          Text(L10n.of(context).invitationToChat),
          inviter(
            context,
            ref,
          ),
        ],
      ),
    );
  }

  ListTile renderDmChatTile(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(invitationUserProfileProvider(invitation)).valueOrNull;

    final senderId = invitation.senderIdStr();

    final roomId = invitation.roomIdStr();
    return ListTile(
      leading: ActerAvatar(
        mode: DisplayMode.DM,
        avatarInfo: AvatarInfo(
          uniqueId: roomId,
          displayName: profile?.displayName,
          avatar: profile?.getAvatarImage(),
        ),
        size: 24,
      ),
      title: (profile?.displayName) != null
          ? Text('${profile?.displayName} ($senderId)')
          : Text(senderId),
      subtitle: Text(L10n.of(context).invitationToDM),
    );
  }

  Chip inviter(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(invitationUserProfileProvider(invitation)).valueOrNull;
    final userId = invitation.senderIdStr();

    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: ActerAvatar(
        mode: DisplayMode.DM,
        avatarInfo: AvatarInfo(
          uniqueId: userId,
          displayName: profile?.displayName,
          avatar: profile?.getAvatarImage(),
        ),
        size: 24,
      ),
      label: Text(profile?.displayName ?? userId),
    );
  }

  // method for post-process invitation accept
  void _onTapAcceptInvite(BuildContext context) async {
    EasyLoading.show(status: L10n.of(context).joining);
    try {
      bool res = await invitation.accept();
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      if (res) {
        EasyLoading.showToast(L10n.of(context).joined);
        if (invitation.room().isSpace()) {
          goToSpace(context, invitation.room().roomIdStr());
        } else {
          goToChat(context, invitation.room().roomIdStr());
        }
      } else {
        EasyLoading.showError(
          L10n.of(context).failedToJoin,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (error) {
      _log.severe('Failure accepting invite', error);
      if (!context.mounted) return;
      EasyLoading.showError(
        L10n.of(context).failedToAcceptInvite(error),
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _onTapDeclineInvite(BuildContext context) async {
    EasyLoading.show(status: L10n.of(context).rejecting);
    try {
      bool res = await invitation.reject();
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      if (res) {
        EasyLoading.showToast(L10n.of(context).rejected);
      } else {
        EasyLoading.showError(
          L10n.of(context).failedToReject,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (error) {
      _log.severe('Failure reject invite', error);
      EasyLoading.showError(
        L10n.of(context).failedToRejectInvite(error),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
