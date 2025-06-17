import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/features/comments/widgets/time_ago_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ActivitySpaceCoreActionsContainerWidget extends ConsumerWidget {
  final ActivityObject? activityObject;
  final String userId;
  final String roomId;
  final String actionTitle;
  final String target;
  final int originServerTs;

  const ActivitySpaceCoreActionsContainerWidget({
    super.key,
    this.activityObject,
    required this.userId,
    required this.roomId,
    required this.actionTitle,
    required this.target,
    required this.originServerTs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarInfo = ref.watch(
      memberAvatarInfoProvider((roomId: roomId, userId: userId)),
    );
    final displayName =
        ref.watch(memberDisplayNameProvider((roomId: roomId, userId: userId))).valueOrNull ??
        userId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildAvatarWithIcon(context, avatarInfo),
          const SizedBox(width: 10),
          _buildSubtitleOrTime(context, displayName),
        ],
      ),
    );
  }

  /// Avatar with Action Icon overlay
  Widget _buildAvatarWithIcon(BuildContext context, AvatarInfo avatarInfo) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ActerAvatar(options: AvatarOptions.DM(avatarInfo, size: 25)),
        Positioned(
          right: -6,
          bottom: -6,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).cardColor,
            ),
            child: Icon(
              PhosphorIconsRegular.pencilSimpleLine,
              color: Colors.white,
              size: 15,
            ),
          ),
        ),
      ],
    );
  }

  /// Subtitle + time or only time if subtitle is null
  Widget _buildSubtitleOrTime(BuildContext context, String displayName) {
    final theme = Theme.of(context);
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: displayName, style: theme.textTheme.bodyMedium),
                TextSpan(
                  text: ' $actionTitle ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.surfaceTint,
                  ),
                ),
              ],
            ),
          ),
          TimeAgoWidget(originServerTs: originServerTs),
        ],
      ),
    );
  }
}
