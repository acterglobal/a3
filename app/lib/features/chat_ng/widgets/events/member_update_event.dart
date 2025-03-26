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

    final eventType = item.eventType();
    final senderId =
        ref
            .watch(
              memberDisplayNameProvider((
                roomId: roomId,
                userId: item.sender(),
              )),
            )
            .valueOrNull ??
        item.sender();

    if (eventType == 'membershipChange') {
      final change = item.msgContent()?.membershipChange();
      if (change == null) return '';
      final userId =
          ref
              .watch(
                memberDisplayNameProvider((
                  roomId: roomId,
                  userId: change.userId().toString(),
                )),
              )
              .valueOrNull ??
          change.userId().toString();
      switch (change.change()) {
        case 'None':
          return lang.chatMembershipNone(userId);
        case 'Error':
          return lang.chatMembershipError(userId);
        case 'Joined':
          return lang.chatMembershipJoined(userId);
        case 'Left':
          return lang.chatMembershipLeft(userId);
        case 'Banned':
          return lang.chatMembershipBanned(senderId, userId);
        case 'Unbanned':
          return lang.chatMembershipUnbanned(senderId, userId);
        case 'Kicked':
          return lang.chatMembershipKicked(senderId, userId);
        case 'Invited':
          return lang.chatMembershipInvited(senderId, userId);
        case 'KickedAndBanned':
          return lang.chatMembershipKickedAndBanned(senderId, userId);
        case 'InvitationAccepted':
          return lang.chatMembershipInvitationAccepted(userId);
        case 'InvitationRejected':
          return lang.chatMembershipInvitationRejected(userId);
        case 'InvitationRevoked':
          return lang.chatMembershipInvitationRevoked(userId);
        case 'Knocked':
          return lang.chatMembershipKnocked(senderId, userId);
        case 'KnockAccepted':
          return lang.chatMembershipKnockAccepted(userId);
        case 'KnockRetracted':
          return lang.chatMembershipKnockRetracted(userId);
        case 'KnockDenied':
          return lang.chatMembershipKnockDenied(userId);
        case 'NotImplemented':
          return lang.chatMembershipNotImplemented(userId);
        default:
          return lang.chatMembershipNone(userId);
      }
    } else if (eventType == 'profileChange') {
      final change = item.msgContent()?.profileChange();
      if (change == null) return '';
      final userId =
          ref
              .watch(
                memberDisplayNameProvider((
                  roomId: roomId,
                  userId: change.userId().toString(),
                )),
              )
              .valueOrNull ??
          change.userId().toString();
      final result = [];
      switch (change.displayNameChange()) {
        case 'ChangedDisplayName':
          final text = lang.chatProfileDisplayNameChanged(
            change.displayNameNewVal() ?? '',
            change.displayNameOldVal() ?? '',
            userId,
          );
          result.add(text);
          break;
        case 'UnsetDisplayName':
          final text = lang.chatProfileDisplayNameUnset(userId);
          result.add(text);
          break;
        case 'SetDisplayName':
          final text = lang.chatProfileDisplayNameSet(
            change.displayNameNewVal() ?? '',
            userId,
          );
          result.add(text);
          break;
      }
      switch (change.avatarUrlChange()) {
        case 'ChangedAvatarUrl':
          final text = lang.chatProfileAvatarUrlChanged(userId);
          result.add(text);
          break;
        case 'UnsetAvatarUrl':
          final text = lang.chatProfileAvatarUrlUnset(userId);
          result.add(text);
          break;
        case 'SetAvatarUrl':
          final text = lang.chatProfileAvatarUrlSet(userId);
          result.add(text);
          break;
      }
      return result.join(', ');
    }
    return '';
  }
}
