import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/features/comments/widgets/time_ago_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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

  const ActivityMembershipItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityObject = activity.object();
    final originServerTs = activity.originServerTs();
    final membershipInfo = _getMembershipInfo(context, ref, activityObject);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(membershipInfo.icon, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    right: 80,
                  ), // Space for TimeAgoWidget
                  child: RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      text: membershipInfo.text,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.surfaceTint,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 3,
                  child: TimeAgoWidget(originServerTs: originServerTs),
                ),
              ],
            ),
          ),
        ],
      ),
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
    final isActionOnMe =
        activity.membershipContent()?.userId().toString() == myId;
    final senderName = _getMemberDisplayName(
      ref,
      activity.roomIdStr(),
      activity.senderIdStr(),
    );
    final targetName = _getMemberDisplayName(
      ref,
      activity.roomIdStr(),
      activity.membershipContent()?.userId().toString() ?? '',
    );

    return switch (activity.membershipContent()?.change()) {
      'joined' => (
        icon: PhosphorIconsThin.users,
        text: lang.chatMembershipOtherJoined(targetName),
      ),
      'left' => (
        icon: PhosphorIconsThin.signOut,
        text: lang.chatMembershipOtherLeft(targetName),
      ),
      //PhosphorIconsThin.userCheck
      'invitationAccepted' => (
        icon: PhosphorIconsThin.userCheck,
        text: lang.chatMembershipInvitationOtherAccepted(targetName),
      ),
      'invitationRejected' => (
        icon: PhosphorIconsThin.userMinus,
        text: lang.chatMembershipInvitationOtherRejected(targetName),
      ),
      'invitationRevoked' => (
        icon: PhosphorIconsThin.minusCircle,
        text: lang.chatMembershipInvitationOtherRevoked(targetName),
      ),
      'knockAccepted' => (
        icon: PhosphorIconsThin.userCheck,
        text: lang.chatMembershipKnockOtherAccepted(targetName),
      ),
      'knockRetracted' => (
        icon: PhosphorIconsThin.userCircleMinus,
        text: lang.chatMembershipKnockOtherRetracted(targetName),
      ),
      'knockDenied' => (
        icon: PhosphorIconsThin.userCircleMinus,
        text: lang.chatMembershipKnockOtherDenied(targetName),
      ),
      'banned' => (
        icon: PhosphorIconsThin.userCircleMinus,
        text:
            isActionOnMe
                ? lang.chatMembershipOtherBannedYou(senderName)
                : lang.chatMembershipOtherBannedOther(senderName, targetName),
      ),
      'unbanned' => (
        icon: PhosphorIconsThin.userCirclePlus,
        text:
            isActionOnMe
                ? lang.chatMembershipOtherUnbannedYou(senderName)
                : lang.chatMembershipOtherUnbannedOther(senderName, targetName),
      ),
      'kicked' => (
        icon: PhosphorIconsThin.userMinus,
        text:
            isActionOnMe
                ? lang.chatMembershipOtherKickedYou(senderName)
                : lang.chatMembershipOtherKickedOther(senderName, targetName),
      ),
      'invited' => (
        icon: PhosphorIconsThin.userPlus,
        text:
            isActionOnMe
                ? lang.chatMembershipOtherInvitedYou(senderName)
                : lang.chatMembershipOtherInvitedOther(senderName, targetName),
      ),
      'kickedAndBanned' => (
        icon: PhosphorIconsThin.userCircleMinus,
        text:
            isActionOnMe
                ? lang.chatMembershipOtherKickedAndBannedYou(senderName)
                : lang.chatMembershipOtherKickedAndBannedOther(
                  senderName,
                  targetName,
                ),
      ),
      'knocked' => (
        icon: PhosphorIconsThin.userPlus,
        text:
            isActionOnMe
                ? lang.chatMembershipOtherKnockedYou(senderName)
                : lang.chatMembershipOtherKnockedOther(senderName, targetName),
      ),
      _ => (
        icon: PhosphorIconsThin.user,
        text: activity.membershipContent()?.change() ?? '',
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
