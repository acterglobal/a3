import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show TimelineEventItem;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MemberUpdateEvent extends ConsumerWidget {
  final bool isMe;
  final String roomId;
  final TimelineEventItem item;
  const MemberUpdateEvent({
    super.key,
    required this.isMe,
    required this.roomId,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String textMsg = getStateEventStr(context, ref, item);

    return Container(
      padding: const EdgeInsets.only(left: 10, bottom: 5, right: 10),
      child: RichText(
        text: TextSpan(
          text: textMsg,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }

  String getStateEventStr(
    BuildContext context,
    WidgetRef ref,
    TimelineEventItem item,
  ) {
    final lang = L10n.of(context);

    final senderId = item.sender();
    final eventType = item.eventType();
    final msgType = item.msgType();
    final firstName =
        ref
            .watch(
              memberDisplayNameProvider((roomId: roomId, userId: senderId)),
            )
            .valueOrNull;
    final msgContent = item.msgContent()?.body() ?? '';

    return switch (eventType) {
      'ProfileChange' => switch (msgType) {
        'ChangedDisplayName' =>
          '${lang.chatDisplayNameUpdate(firstName ?? senderId)} $msgContent',
        'SetDisplayName' =>
          '${lang.chatDisplayNameSet(firstName ?? senderId)}: $msgContent',
        'RemoveDisplayName' => lang.chatDisplayNameUnset(firstName ?? senderId),
        'ChangeProfileAvatar' => lang.chatUserAvatarChange(
          firstName ?? senderId,
        ),
        _ => msgContent,
      },
      _ => switch (msgType) {
        'Joined' =>
          isMe
              ? lang.chatYouJoined
              : firstName != null
              ? lang.chatJoinedDisplayName(firstName)
              : lang.chatJoinedUserId(senderId),
        'Left' =>
          isMe ? lang.chatYouLeft : lang.chatUserLeft(firstName ?? senderId),
        'Banned' =>
          isMe
              ? lang.chatYouBanned(msgContent)
              : lang.chatUserBanned(firstName ?? senderId, msgContent),
        'Unbanned' =>
          isMe
              ? lang.chatYouUnbanned(msgContent)
              : lang.chatUserUnbanned(firstName ?? senderId, msgContent),
        'Kicked' =>
          isMe
              ? lang.chatYouKicked(msgContent)
              : lang.chatUserKicked(firstName ?? senderId, msgContent),
        'KickedAndBanned' =>
          isMe
              ? lang.chatYouKickedBanned(msgContent)
              : lang.chatUserKickedBanned(firstName ?? senderId, msgContent),
        'InvitationAccepted' =>
          isMe
              ? lang.chatYouAcceptedInvite
              : firstName != null
              ? lang.chatInvitationAcceptedDisplayName(firstName)
              : lang.chatInvitationAcceptedUserId(senderId),
        'Invited' =>
          (() {
            final inviteeId = msgContent;
            final inviteeName =
                ref
                    .watch(
                      memberDisplayNameProvider((
                        roomId: roomId,
                        userId: inviteeId,
                      )),
                    )
                    .valueOrNull;
            return isMe
                ? lang.chatYouInvited(inviteeName ?? inviteeId)
                : firstName != null && inviteeName != null
                ? lang.chatInvitedDisplayName(inviteeName, firstName)
                : lang.chatInvitedUserId(inviteeId, senderId);
          })(),
        _ => msgContent,
      },
    };
  }
}
