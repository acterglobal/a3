import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show RoomEventItem;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MemberUpdateEvent extends ConsumerWidget {
  final bool isMe;
  final String roomId;
  final RoomEventItem item;
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
    RoomEventItem item,
  ) {
    final lang = L10n.of(context);

    final senderId = item.sender();
    final eventType = item.eventType();
    final firstName =
        ref
            .watch(
              memberDisplayNameProvider((roomId: roomId, userId: senderId)),
            )
            .valueOrNull;

    if (eventType == 'MembershipChange') {
      final change = item.msgContent()?.membershipChange();
      if (change == null) return '';
      final mode = change.change();
      final userId = firstName ?? change.userId().toString();
      switch (mode) {
        case 'None':
          return lang.chatMembershipNone(userId);
        case 'Error':
          return lang.chatMembershipError(userId);
        case 'Joined':
          return lang.chatMembershipJoined(userId);
        case 'Left':
          return lang.chatMembershipLeft(userId);
        case 'Banned':
          return lang.chatMembershipBanned(userId);
        case 'Unbanned':
          return lang.chatMembershipUnbanned(userId);
        case 'Kicked':
          return lang.chatMembershipKicked(userId);
        case 'Invited':
          return lang.chatMembershipInvited(userId);
        case 'KickedAndBanned':
          return lang.chatMembershipKickedAndBanned(userId);
        case 'InvitationAccepted':
          return lang.chatMembershipInvitationAccepted(userId);
        case 'InvitationRejected':
          return lang.chatMembershipInvitationRejected(userId);
        case 'InvitationRevoked':
          return lang.chatMembershipInvitationRevoked(userId);
        case 'Knocked':
          return lang.chatMembershipKnocked(userId);
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
    } else if (eventType == 'ProfileChange') {
      final change = item.msgContent()?.profileChange();
      if (change == null) return '';
      final userId = firstName ?? change.userId().toString();
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
