import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/activities/providers/invitations_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Invitation;
import 'package:extension_nullable/extension_nullable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          const Divider(indent: 5),
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
                  onPressed: () => _onTapAcceptInvite(context, ref),
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
    final roomAvatarInfo =
        ref.watch(roomAvatarInfoProvider(invitation.roomIdStr()));

    final roomId = invitation.roomIdStr();
    return ListTile(
      leading: ActerAvatar(
        options: AvatarOptions(
          roomAvatarInfo,
          size: 48,
        ),
      ),
      title: Text(roomAvatarInfo.displayName ?? roomId),
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
    final roomAvatarInfo =
        ref.watch(roomAvatarInfoProvider(invitation.roomIdStr()));

    return ListTile(
      leading: ActerAvatar(
        options: AvatarOptions(
          roomAvatarInfo,
          size: 48,
        ),
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
    final title =
        profile?.displayName.map((p0) => '$p0 ($senderId)') ?? senderId;
    return ListTile(
      leading: ActerAvatar(
        options: AvatarOptions.DM(
          AvatarInfo(
            uniqueId: invitation.roomIdStr(),
            displayName: profile?.displayName,
            avatar: profile?.avatar,
          ),
          size: 48,
        ),
      ),
      title: Text(title),
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
        options: AvatarOptions.DM(
          AvatarInfo(
            uniqueId: userId,
            displayName: profile?.displayName,
            avatar: profile?.avatar,
          ),
          size: 24,
        ),
      ),
      label: Text(profile?.displayName ?? userId),
    );
  }

  // method for post-process invitation accept
  void _onTapAcceptInvite(BuildContext context, WidgetRef ref) async {
    EasyLoading.show(status: L10n.of(context).joining);
    final client = ref.read(alwaysClientProvider);
    final roomId = invitation.roomIdStr();
    final isSpace = invitation.room().isSpace();
    final lang = L10n.of(context);
    try {
      await invitation.accept();
    } catch (e, s) {
      _log.severe('Failure accepting invite', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.failedToAcceptInvite(e),
        duration: const Duration(seconds: 3),
      );
      return;
    }

    try {
      // timeout to wait for 10seconds to ensure the room is ready
      await client.waitForRoom(roomId, 10);
    } catch (e, s) {
      _log.warning('Joining $roomId didn’t return within 10 seconds', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(lang.joinedDelayed);
      // do not forward in this case
      return;
    }
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.showToast(lang.joined);
    if (isSpace) {
      goToSpace(context, roomId);
    } else {
      goToChat(context, roomId);
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
        _log.severe('Failed to reject invitation');
        EasyLoading.showError(
          L10n.of(context).failedToReject,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e, s) {
      _log.severe('Failure reject invite', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).failedToRejectInvite(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
