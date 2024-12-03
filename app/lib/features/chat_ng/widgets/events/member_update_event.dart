import 'package:acter/common/utils/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show RoomEventItem;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class MemberUpdateEvent extends StatelessWidget {
  final bool isUser;
  final RoomEventItem item;
  const MemberUpdateEvent({
    super.key,
    required this.isUser,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    late String textMsg;
    final senderId = item.sender();
    final msgType = item.msgType();
    final firstName = simplifyUserId(senderId);

    if (msgType == 'Joined') {
      if (isUser) {
        textMsg = lang.chatYouJoined;
      } else if (firstName != null) {
        textMsg = lang.chatJoinedDisplayName(firstName);
      } else {
        textMsg = lang.chatJoinedUserId(senderId);
      }
    } else if (msgType == 'InvitationAccepted') {
      if (isUser) {
        textMsg = lang.chatYouAcceptedInvite;
      } else if (firstName != null) {
        textMsg = lang.chatInvitationAcceptedDisplayName(firstName);
      } else {
        textMsg = lang.chatInvitationAcceptedUserId(senderId);
      }
    } else if (msgType == 'Invited') {
      if (isUser) {
        textMsg = lang.chatYouInvited;
      } else if (firstName != null) {
        textMsg = lang.chatInvitedDisplayName(firstName);
      } else {
        textMsg = lang.chatInvitedUserId(senderId);
      }
    } else {
      textMsg = item.msgContent()?.body() ?? '';
    }

    return Container(
      padding: const EdgeInsets.only(
        left: 10,
        bottom: 5,
        right: 10,
      ),
      child: RichText(
        text: TextSpan(
          text: textMsg,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}
