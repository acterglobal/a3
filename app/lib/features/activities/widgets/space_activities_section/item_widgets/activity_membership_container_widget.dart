import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/widgets/acter_icon_picker/utils.dart';
import 'package:acter/features/comments/widgets/time_ago_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A widget that displays membership change events in a space's activity feed.
/// 
/// This widget shows information about various membership changes like:
/// - Users joining/leaving a space
/// - Invitations being sent/accepted/rejected
/// - Users being banned/unbanned
/// - Knock requests and their status
class ActivityMembershipItemWidget extends ConsumerWidget {
  /// The activity containing membership change information
  final Activity activity;

  const ActivityMembershipItemWidget({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityObject = activity.object();
    final originServerTs = activity.originServerTs();
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionInfoUI(context, ref, activityObject),
            const SizedBox(height: 6),
            _buildUserInfoUI(context, ref),
            TimeAgoWidget(originServerTs: originServerTs),
          ],
        ),
      ),
    );
  }

  /// Builds the UI section showing the membership change action and its details
  Widget _buildActionInfoUI(BuildContext context, WidgetRef ref, ActivityObject? activityObject) {
    final membershipInfo = _getMembershipInfo(context, ref, activityObject);

    final actionTitleStyle = Theme.of(context).textTheme.labelMedium;
    final actionIconColor = Theme.of(context).colorScheme.onSurface;
    
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

  /// Builds the UI section showing the user involved in the membership change
  Widget _buildUserInfoUI(BuildContext context, WidgetRef ref) {
    final roomId = activity.roomIdStr();
    final userId = activity.membershipContent()?.userId().toString() ?? '';
    final memberInfo = ref.watch(
      memberAvatarInfoProvider((roomId: roomId, userId: userId)),
    );
    
    return ListTile(
      horizontalTitleGap: 6,
      contentPadding: const EdgeInsets.only(top: 10),
      leading: ActerAvatar(options: AvatarOptions.DM(memberInfo, size: 32)),
      title: Text(memberInfo.displayName ?? userId),
    );
  }

  /// Returns the appropriate icon and text for the membership change type
  ({IconData icon, String text}) _getMembershipInfo(
    BuildContext context,
    WidgetRef ref,
    ActivityObject? activityObject,
  ) {
    final lang = L10n.of(context);
    final myId = ref.watch(myUserIdStrProvider);
    final isActionOnMe = activity.membershipContent()?.userId().toString() == myId;
    final senderName = _getMemberDisplayName(ref, activity.roomIdStr(), activity.senderIdStr());
    final targetName = _getMemberDisplayName(
      ref,
      activity.roomIdStr(),
      activity.membershipContent()?.userId().toString() ?? '',
    );

    return switch (activity.membershipContent()?.change()) {
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
          text: activity.membershipContent()?.change() ?? ''
        ),
    };
  }

  /// Helper method to get a member's display name
  String _getMemberDisplayName(WidgetRef ref, String roomId, String userId) {
    final memberInfo = ref.watch(
      memberAvatarInfoProvider((roomId: roomId, userId: userId)),
    );
    return memberInfo.displayName ?? userId;
  }
}
