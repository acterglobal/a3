import 'dart:typed_data';
import 'package:acter/features/invitations/providers/invitations_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/preview/actions/show_room_preview.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show RoomInvitation;
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::activities::invitation_widget');

class InvitationItemWidget extends ConsumerStatefulWidget {
  final RoomInvitation invitation;

  const InvitationItemWidget({super.key, required this.invitation});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _InvitationWidgetState();
}

class _InvitationWidgetState extends ConsumerState<InvitationItemWidget> {
  String? roomTitle;
  late AvatarInfo avatarInfo;

  L10n get lang => L10n.of(context);
  bool get isDM => widget.invitation.isDm();
  bool get isSpace => widget.invitation.room().isSpace();
  String get roomId => widget.invitation.roomIdStr();
  String get senderId => widget.invitation.senderIdStr();
  dynamic get profile =>
      ref.watch(invitationUserProfileProvider(widget.invitation)).valueOrNull;

  @override
  void initState() {
    super.initState();
    avatarInfo = AvatarInfo(uniqueId: roomId);
    _fetchDetails();
  }

  void _fetchDetails() async {
    final room = widget.invitation.room();
    final title = await room.displayName();
    setState(() {
      roomTitle = title.text();
      avatarInfo = AvatarInfo(uniqueId: roomId, displayName: roomTitle);
    });
    final avatarData = (await room.avatar(null)).data();
    if (avatarData != null) {
      setState(() {
        avatarInfo = AvatarInfo(
          uniqueId: roomId,
          displayName: roomTitle,
          avatar: MemoryImage(Uint8List.fromList(avatarData.asTypedList())),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildLeadingImageUI(),
            const SizedBox(width: 12),
            Expanded(child: buildContentUI(context)),
          ],
        ),
      ),
    );
  }

  Widget buildLeadingImageUI() {
    return ActerAvatar(
      options:
          isDM
              ? AvatarOptions.DM(
                AvatarInfo(
                  uniqueId: roomId,
                  displayName: profile?.displayName,
                  avatar: profile?.avatar,
                ),
                size: 24,
              )
              : AvatarOptions(avatarInfo, size: 48),
    );
  }

  Widget buildContentUI(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildTitle(context),
        const SizedBox(height: 4),
        buildInvitationType(context),
        const SizedBox(height: 8),
        buildActionButtons(context),
      ],
    );
  }

  Widget buildTitle(BuildContext context) {
    return GestureDetector(
      onTap: () => showRoomPreview(context: context, roomIdOrAlias: roomId),
      child: Text(
        isDM ? (profile?.displayName ?? senderId) : (roomTitle ?? roomId),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget buildInvitationType(BuildContext context) {
    final inviterName = profile?.displayName ?? senderId;
    final inviteTypeTextStyle = Theme.of(context).textTheme.labelLarge;
    return isDM
        ? Text(lang.invitationToDM, style: inviteTypeTextStyle)
        : Wrap(
          children: [
            Text(
              isSpace ? lang.invitationToSpace : lang.invitationToChat,
              style: inviteTypeTextStyle,
            ),
            Text(
              inviterName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        );
  }

  Widget buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: () => _onTapAcceptInvite(context),
          child: Text(isDM ? lang.startDM : lang.accept),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () => _onTapDeclineInvite(context),
          child: Text(lang.decline),
        ),
      ],
    );
  }

  void _onTapAcceptInvite(BuildContext context) async {
    final lang = L10n.of(context);
    EasyLoading.show(status: lang.joining);
    final client = await ref.read(alwaysClientProvider.future);
    try {
      await widget.invitation.accept();
      ref.invalidate(invitationListProvider);
    } catch (e, s) {
      _log.severe('Failure accepting invite', e, s);
      ref.invalidate(invitationListProvider);
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
    } catch (e) {
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
    final lang = L10n.of(context);
    EasyLoading.show(status: lang.rejecting);
    try {
      bool res = await widget.invitation.reject();
      ref.invalidate(invitationListProvider);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      if (res) {
        EasyLoading.showToast(lang.rejected);
      } else {
        _log.severe('Failed to reject invitation');
        EasyLoading.showError(
          lang.failedToReject,
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
        lang.failedToRejectInvite(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
