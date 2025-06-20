import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/features/comments/widgets/time_ago_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ActivityIndividualActionContainerWidget extends ConsumerWidget {
  final ActivityObject? activityObject;
  final String userId;
  final String roomId;
  final String actionTitle;
  final IconData actionIcon;
  final Color? actionIconBgColor;
  final Color? actionIconColor;
  final String target;
  final int originServerTs;

  const ActivityIndividualActionContainerWidget({
    super.key,
    this.activityObject,
    required this.userId,
    required this.roomId,
    required this.actionTitle,
    required this.actionIcon,
    this.actionIconColor,
    this.actionIconBgColor,
    required this.target,
    required this.originServerTs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final avatarInfo = ref.watch(
      memberAvatarInfoProvider((roomId: roomId, userId: userId)),
    );
    final displayName =
        ref.watch(memberDisplayNameProvider((roomId: roomId, userId: userId))).valueOrNull ??
        userId;

    return Container(
      padding: const EdgeInsets.symmetric( vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatarWithIcon(context, avatarInfo),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDisplayNameAndAction(context, theme, displayName),
                const SizedBox(height: 4),
                _buildSubtitleOrTime(context, displayName),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Avatar with Action Icon overlay
  Widget _buildAvatarWithIcon(BuildContext context, AvatarInfo avatarInfo) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ActerAvatar(options: AvatarOptions.DM(avatarInfo, size: 22)),
        Positioned(
          right: -6,
          bottom: -6,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: actionIconBgColor ?? Theme.of(context).cardColor,
            ),
            child: Icon(actionIcon, color: actionIconColor ?? Colors.white, size: 15),
          ),
        ),
      ],
    );
  }

  /// RichText for displayName, action, and target
  Widget _buildDisplayNameAndAction(
    BuildContext context,
    ThemeData theme,
    String displayName,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            target,
            style: theme.textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (activityObject != null)
          Icon(
            _getActivityObjectIcon(),
            size: 16,
            color: colorScheme.surfaceTint,
          ),
      ],
    );
  }

  /// Subtitle + time or only time if subtitle is null
  Widget _buildSubtitleOrTime(BuildContext context, String displayName) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 1,
          child: RichText(
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
        ),
        TimeAgoWidget(originServerTs: originServerTs),
      ],
    );
  }

  IconData _getActivityObjectIcon() {
    return switch (activityObject?.typeStr()) {
      'news' => PhosphorIconsRegular.rocketLaunch,
      'story' => PhosphorIconsRegular.book,
      'event' => PhosphorIconsRegular.calendar,
      'pin' => PhosphorIconsRegular.pushPin,
      'task-list' => PhosphorIconsRegular.listChecks,
      'task' => PhosphorIconsRegular.checkCircle,
      _ => PhosphorIconsRegular.question,
    };
  }
}
