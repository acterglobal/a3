import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/widgets/acter_icon_picker/utils.dart';
import 'package:acter/features/comments/widgets/time_ago_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//Main container for all activity item widgets
class ActivityMembershipItemContainerWidget extends ConsumerWidget {
  final Color? actionIconColor;
  final ActivityObject? activityObject;
  final String userId;
  final String roomId;
  final String? senderId;
  final Widget? subtitle;
  final int originServerTs;
  final MembershipContent? membershipContent;

  const ActivityMembershipItemContainerWidget({
    super.key,
    this.actionIconColor,
    this.activityObject,
    required this.userId,
    required this.roomId,
    this.senderId,
    this.subtitle,
    required this.originServerTs,
    this.membershipContent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              buildActionInfoUI(context, ref),
              const SizedBox(height: 6),
              buildUserInfoUI(context, ref),
              TimeAgoWidget(originServerTs: originServerTs),
            ],
          ),
        ),
    );
  }

  Widget buildActionInfoUI(BuildContext context, WidgetRef ref) {
    final actionTitleStyle = Theme.of(context).textTheme.labelMedium;
    final membershipInfo = _getMembershipInfo(context, ref);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Icon(membershipInfo.icon, size: 16, color: actionIconColor),
        const SizedBox(width: 4),
        Text(membershipInfo.text, style: actionTitleStyle),
        const SizedBox(width: 4),
        ActerIconWidgetFromObjectIdAndType(
          objectId: activityObject?.objectIdStr(),
          objectType: activityObject?.typeStr(),
          fallbackWidget: SizedBox.shrink(),
          iconSize: 24,
        ),
      ],
    );
  }

  Widget buildUserInfoUI(BuildContext context, WidgetRef ref) {
    final memberInfo = ref.watch(
      memberAvatarInfoProvider((roomId: roomId, userId: userId)),
    );
    return ListTile(
      horizontalTitleGap: 6,
      contentPadding: EdgeInsets.only(top: 10),
      leading: ActerAvatar(options: AvatarOptions.DM(memberInfo, size: 32)),
      title: Text(memberInfo.displayName ?? userId),
    );
  }

  ({IconData icon, String text}) _getMembershipInfo(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final myId = ref.watch(myUserIdStrProvider);
    final isActionOnMe = userId == myId;
    final senderName = ref.watch(memberAvatarInfoProvider((roomId: roomId, userId: senderId ?? ''))).displayName ?? senderId ?? '';
    final targetName = ref.watch(memberAvatarInfoProvider((roomId: roomId, userId: userId))).displayName ?? userId;

    return switch (membershipContent?.change()) {
      'joined' => (
          icon: Icons.people_sharp,
          text: lang.chatMembershipOtherJoined(targetName)
        ),
      'left' => (
          icon: Icons.logout,
          text: lang.chatMembershipOtherLeft(targetName)
        ),
      'invitationAccepted' => (
          icon: Icons.person_add,
          text: lang.chatMembershipInvitationOtherAccepted(targetName)
        ),
      'invitationRejected' => (
          icon: Icons.person_off,
          text: lang.chatMembershipInvitationOtherRejected(targetName)
        ),
      'invitationRevoked' => (
          icon: Icons.person_remove,
          text: lang.chatMembershipInvitationOtherRevoked(targetName)
        ),
      'knockAccepted' => (
          icon: Icons.person_add,
          text: lang.chatMembershipKnockOtherAccepted(targetName)
        ),
      'knockRetracted' => (
          icon: Icons.person_remove,
          text: lang.chatMembershipKnockOtherRetracted(targetName)
        ),
      'knockDenied' => (
          icon: Icons.block,
          text: lang.chatMembershipKnockOtherDenied(targetName)
        ),
      'banned' => (
          icon: Icons.block,
          text: isActionOnMe
              ? lang.chatMembershipOtherBannedYou(senderName)
              : lang.chatMembershipOtherBannedOther(senderName, targetName)
        ),
      'unbanned' => (
          icon: Icons.block_flipped,
          text: isActionOnMe
              ? lang.chatMembershipOtherUnbannedYou(senderName)
              : lang.chatMembershipOtherUnbannedOther(senderName, targetName)
        ),
      'kicked' => (
          icon: Icons.person_remove,
          text: isActionOnMe
              ? lang.chatMembershipOtherKickedYou(senderName)
              : lang.chatMembershipOtherKickedOther(senderName, targetName)
        ),
      'invited' => (
          icon: Icons.person_add,
          text: isActionOnMe
              ? lang.chatMembershipOtherInvitedYou(senderName)
              : lang.chatMembershipOtherInvitedOther(senderName, targetName)
        ),
      'kickedAndBanned' => (
          icon: Icons.block,
          text: isActionOnMe
              ? lang.chatMembershipOtherKickedAndBannedYou(senderName)
              : lang.chatMembershipOtherKickedAndBannedOther(senderName, targetName)
        ),
      'knocked' => (
          icon: Icons.person_add,
          text: isActionOnMe
              ? lang.chatMembershipOtherKnockedYou(senderName)
              : lang.chatMembershipOtherKnockedOther(senderName, targetName)
        ),
      _ => (
          icon: Icons.person,
          text: membershipContent?.change() ?? ''
        ),
    };
  }
}
